//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit
import ClientRuntime
import XCTest

/**
 Includes Utility functions for Http Protocol Request Serialization Tests
 */
public typealias ValidateCallback = (Data, Data) -> Void

open class HttpRequestTestBase: XCTestCase {

    open override func setUp() {
        AwsCommonRuntimeKit.initialize()
    }

    /**
     Create `HttpRequest` from its components
     */
    public func buildExpectedHttpRequest(method: HttpMethodType,
                                         path: String,
                                         headers: [String: String]? = nil,
                                         forbiddenHeaders: [String]? = nil,
                                         requiredHeaders: [String]? = nil,
                                         queryParams: [String]? = nil,
                                         forbiddenQueryParams: [String]? = nil,
                                         requiredQueryParams: [String]? = nil,
                                         body: String?,
                                         host: String,
                                         resolvedHost: String?) -> ExpectedSdkHttpRequest {
        let builder = ExpectedSdkHttpRequestBuilder()
        builder.withMethod(method)

        if let deconflictedHost = deconflictHost(host: host, resolvedHost: resolvedHost) {
            builder.withHost(deconflictedHost)
        }
        builder.withPath(path)
        
        if let queryParams = queryParams {
            addQueryItems(queryParams: queryParams, builder: builder)
        }
        
        if let forbiddenQueryParams = forbiddenQueryParams {
            addForbiddenQueryItems(queryParams: forbiddenQueryParams, builder: builder)
        }
        
        if let requiredQueryParams = requiredQueryParams {
            addRequiredQueryItems(queryParams: requiredQueryParams, builder: builder)
        }
        
        if let headers = headers {
            for (headerName, headerValue) in headers {
                let value = sanitizeStringForNonConformingValues(headerValue)
                builder.withHeader(name: headerName, value: value)
            }
        }
        
        if let forbiddenHeaders = forbiddenHeaders {
            for headerName in forbiddenHeaders {
                builder.withForbiddenHeader(name: headerName)
            }
        }
        
        if let requiredHeaders = requiredHeaders {
            for headerName in requiredHeaders {
                builder.withRequiredHeader(name: headerName)
            }
        }

        guard let body = body else {
            return builder.build()
        }
        // handle empty string body cases that should still create a request
        // without the body
        if body != "" {
            let httpBody = HttpBody.data(body.data(using: .utf8))
            builder.withBody(httpBody)
        }
    
        return builder.build()
        
    }

    func deconflictHost(host: String, resolvedHost: String?) -> String? {
        var deconflictedHost: String?
        if !host.isEmpty,
           let urlFromHost = ClientRuntime.URL(string: "http://\(host)"),
           let parsedHost = urlFromHost.host {
            deconflictedHost = parsedHost
        }
        if let resolvedHost = resolvedHost, !resolvedHost.isEmpty {
            deconflictedHost = resolvedHost
        }
        return deconflictedHost
    }

    public func urlPrefixFromHost(host: String) -> String? {
        guard !host.isEmpty, let hostCustomPath = URL(string: "http://\(host)")?.path else {
            return nil
        }
        return hostCustomPath
    }

    // Per spec, host can contain a path prefix, so this function is used to get only the host
    // https://awslabs.github.io/smithy/1.0/spec/http-protocol-compliance-tests.html#smithy-test-httprequesttests-trait
    public func hostOnlyFromHost(host: String) -> String? {
        guard !host.isEmpty, let hostOnly = URL(string: "http://\(host)")?.host else {
            return nil
        }
        return hostOnly
    }
    
    func addQueryItems(queryParams: [String], builder: ExpectedSdkHttpRequestBuilder) {
        for queryParam in queryParams {
            let queryParamComponents = queryParam.components(separatedBy: "=")
            if queryParamComponents.count > 1 {
                let value = sanitizeStringForNonConformingValues(queryParamComponents[1])

                builder.withQueryItem(URLQueryItem(name: queryParamComponents[0],
                                                   value: value))
            } else {
                builder.withQueryItem(URLQueryItem(name: queryParamComponents[0], value: nil))
            }
        }
    }
    
    func addForbiddenQueryItems(queryParams: [String], builder: ExpectedSdkHttpRequestBuilder) {
        for queryParam in queryParams {
            let queryParamComponents = queryParam.components(separatedBy: "=")
            if queryParamComponents.count > 1 {
                let value = sanitizeStringForNonConformingValues(queryParamComponents[1])

                builder.withForbiddenQueryItem(URLQueryItem(name: queryParamComponents[0],
                                                   value: value))
            } else {
                builder.withForbiddenQueryItem(URLQueryItem(name: queryParamComponents[0], value: nil))
            }
        }
    }
    
    func addRequiredQueryItems(queryParams: [String], builder: ExpectedSdkHttpRequestBuilder) {
        for queryParam in queryParams {
            let queryParamComponents = queryParam.components(separatedBy: "=")
            if queryParamComponents.count > 1 {
                let value = sanitizeStringForNonConformingValues(queryParamComponents[1])

                builder.withRequiredQueryItem(URLQueryItem(name: queryParamComponents[0],
                                                   value: value))
            } else {
                builder.withRequiredQueryItem(URLQueryItem(name: queryParamComponents[0], value: nil))
            }
        }
    }
    
    func sanitizeStringForNonConformingValues(_ input: String) -> String {
        switch input {
        case "Infinity": return "inf"
        case "-Infinity": return "-inf"
        case "NaN": return "nan"
        default:
            return input
        }
    }
    
    /**
     Check if a Query Item with given name exists in array of `URLQueryItem`
     */
    public func queryItemExists(_ queryItemName: String, in queryItems: [URLQueryItem]?) -> Bool {
        guard let queryItems = queryItems else {
            return false
        }

        for queryItem in queryItems where queryItem.name == queryItemName {
            return true
        }
        return false
    }
    
    /**
    Check if a header with given name exists in array of `Header`
    */
    public func headerExists(_ headerName: String, in headers: [Header]) -> Bool {
        for header in headers where header.name == headerName {
            return true
        }
        return false
    }
    
    /**
     Asserts `HttpRequest` objects match
     /// - Parameter expected: Expected `HttpRequest`
     /// - Parameter actual: Actual `HttpRequest` to compare against
     /// - Parameter assertEqualHttpBody: Close to assert equality of `HttpBody` components
     */
    public func assertEqual(
        _ expected: ExpectedSdkHttpRequest,
        _ actual: SdkHttpRequest,
        _ assertEqualHttpBody: ((HttpBody?, HttpBody?) -> Void)? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        // assert headers match
        assertHttpHeaders(expected.headers, actual.headers, file: file, line: line)
        
        assertForbiddenHeaders(expected.forbiddenHeaders, actual.headers, file: file, line: line)
        
        assertRequiredHeaders(expected.requiredHeaders, actual.headers, file: file, line: line)
        
        assertQueryItems(expected.queryItems, actual.queryItems, file: file, line: line)
        
        XCTAssertEqual(expected.endpoint.path, actual.endpoint.path, file: file, line: line)
        XCTAssertEqual(expected.endpoint.host, actual.endpoint.host, file: file, line: line)
        XCTAssertEqual(expected.method, actual.method, file: file, line: line)
        assertForbiddenQueryItems(expected.forbiddenQueryItems, actual.queryItems, file: file, line: line)
        
        assertRequiredQueryItems(expected.requiredQueryItems, actual.queryItems, file: file, line: line)
        
        // assert the contents of HttpBody match, if no body was on the test, no assertions are to be made about the body
        // https://awslabs.github.io/smithy/1.0/spec/http-protocol-compliance-tests.html#httprequesttests
        if let assertEqualHttpBody = assertEqualHttpBody {
            assertEqualHttpBody(expected.body, actual.body)
        }
    }
    
    public func genericAssertEqualHttpBodyData(
        _ expected: HttpBody,
        _ actual: HttpBody,
        _ encoder: Any,
        _ callback: (Data, Data) -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .success(let expectedData) = extractData(expected) else {
            XCTFail("Failed to extract data from httpbody for expected", file: file, line: line)
            return
        }
        guard case .success(let actualData) = extractData(actual) else {
            XCTFail("Failed to extract data from httpbody for actual", file: file, line: line)
            return
        }
        if shouldCompareData(expectedData, actualData) {
            if encoder is XMLEncoder {
                XCTAssertXMLDataEqual(actualData!, expectedData!, file: file, line: line)
            } else if encoder is JSONEncoder {
                XCTAssertJSONDataEqual(actualData!, expectedData!, file: file, line: line)
            }
            callback(expectedData!, actualData!)
        }
    }

    private func extractData(_ httpBody: HttpBody) -> Result<Data?, Error> {
        switch httpBody {
        case .data(let actualData):
            return .success(actualData)
        case .stream(let byteStream):
            switch byteStream {
            case .buffer(let byteBuffer):
                return .success(byteBuffer.toData())
            case .reader(let streamReader):
                return .success(streamReader.read(maxBytes: nil, rewind: false).toData())
            }
           
        case .none:
            return .failure(InternalHttpRequestTestBaseError("HttpBody is not Data Type"))
        }
    }

    private func shouldCompareData(_ expected: Data?, _ actual: Data?) -> Bool {
        if expected == nil && actual == nil {
            return false
        } else if expected != nil && actual == nil {
            XCTFail("actual data in HttpBody is nil but expected is not")
            return false
        } else if expected == nil && actual != nil {
            XCTFail("expected data in HttpBody is nil but actual is not")
            return false
        }
        return true
    }

    /**
    Asserts `HttpHeaders` objects  match
    /// - Parameter expected: Expected `HttpHeaders`
    /// - Parameter actual: Actual `HttpHeaders` to compare against
    */
    public func assertHttpHeaders(
        _ expected: Headers?,
        _ actual: Headers?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let expected = expected else {
            return
        }
        
        guard let actual = actual else {
            XCTFail("There are expected headers and no actual headers.", file: file, line: line)
            return
        }
        
        expected.headers.forEach { header in
            XCTAssertTrue(actual.exists(name: header.name), file: file, line: line)
            
            guard actual.values(for: header.name) != header.value else {
                XCTAssertEqual(actual.values(for: header.name), header.value, file: file, line: line)
                return
            }
            
            let actualValue = actual.values(for: header.name)?.joined(separator: ", ")
            XCTAssertNotNil(actualValue, file: file, line: line)
            
            let expectedValue = header.value.joined(separator: ", ")
            XCTAssertEqual(actualValue, expectedValue, file: file, line: line)
        }
    }
    
    public func assertForbiddenHeaders(
        _ expected: [String]?,
        _ actual: Headers,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let expected = expected else {
            return
        }

        for forbiddenHeaderName in expected {
            XCTAssertFalse(actual.exists(name: forbiddenHeaderName),
                           """
                           forbidden header found: \(forbiddenHeaderName):
                           \(String(describing: actual.value(for: forbiddenHeaderName)))
                           """,
                           file: file,
                           line: line
            )
        }
    }
    
    public func assertRequiredHeaders(
        _ expected: [String]?,
        _ actual: Headers,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let expected = expected else {
            return
        }

        for requiredHeaderName in expected {
            XCTAssertTrue(actual.exists(name: requiredHeaderName),
                          """
                          expected required header not found: \(requiredHeaderName):
                          \(String(describing: actual.value(for: requiredHeaderName)))
                          """,
                          file: file,
                          line: line
            )
        }
    }
    
    public func assertQueryItems(
        _ expected: [URLQueryItem]?,
        _ actual: [URLQueryItem]?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let expectedQueryItems = expected else {
            return
        }
        guard let actualQueryItems = actual else {
            XCTFail("actual query items in Endpoint is nil but expected are not", file: file, line: line)
            return
        }
        
        for expectedQueryItem in expectedQueryItems {
            let values = actualQueryItems.filter {$0.name == expectedQueryItem.name}.map { $0.value}
            XCTAssertNotNil(
                values,
                "expected query parameter \(expectedQueryItem.name); no values found",
                file: file,
                line: line
            )
            XCTAssertTrue(values.contains(expectedQueryItem.value),
                          """
                          expected query item not found.
                          Expected Value: \(expectedQueryItem.value ?? "nil")
                          Actual Values: \(values)
                          """,
                          file: file,
                          line: line
            )
        }
    }
    
    public func assertForbiddenQueryItems(
        _ expected: [URLQueryItem]?,
        _ actual: [URLQueryItem]?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let forbiddenQueryItems = expected else {
            return
        }
        guard let actualQueryItems = actual else {
            return
        }
        
        for forbiddenQueryItem in forbiddenQueryItems {
            XCTAssertFalse(actualQueryItems.contains(where: {$0.name == forbiddenQueryItem.name &&
                $0.value == forbiddenQueryItem.value}),
                           "forbidden query parameter item found:\(forbiddenQueryItem)",
            file: file,
            line: line
            )
        }
    }
    
    public func assertRequiredQueryItems(
        _ expected: [URLQueryItem]?,
        _ actual: [URLQueryItem]?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let requiredQueryItems = expected else {
            return
        }
        guard let actualQueryItems = actual else {
            XCTFail("actual query items in Endpoint is nil but required are not", file: file, line: line)
            return
        }
        
        for requiredQueryItem in requiredQueryItems {
            XCTAssertTrue(actualQueryItems.contains(where: {$0.name == requiredQueryItem.name &&
                $0.value == requiredQueryItem.value}),
                          "expected required query parameter not found:\(requiredQueryItem)",
                          file: file,
                          line: line
            )
        }
    }
    
    struct InternalHttpRequestTestBaseError: Error {
        let localizedDescription: String
        public init(_ description: String) {
            self.localizedDescription = description
        }
    }
}

extension Array where Element: Comparable {
    func containsSameElements(as other: [Element]) -> Bool {
        return self.count == other.count && self.sorted() == other.sorted()
    }
}