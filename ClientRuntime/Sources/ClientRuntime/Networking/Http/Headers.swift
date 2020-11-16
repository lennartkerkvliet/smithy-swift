//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

import AwsCommonRuntimeKit

public struct Headers {
    public var headers: [Header] = []

    /// Creates an empty instance.
    public init() {}

    /// Creates an instance from a `[String: String]`. Duplicate case-insensitive names are collapsed into the last name
    /// and value encountered.
    public init(_ dictionary: [String: String]) {
        self.init()

        dictionary.forEach { add(name: $0.key, value: $0.value)}
    }
    
    /// Creates an instance from a `[String: [String]]`. 
    public init(_ dictionary: [String: [String]]) {
        self.init()

        dictionary.forEach { key, value in value.forEach {add(name: key, value: $0) }}
    }

    /// Case-insensitively updates or appends an `HTTPHeader` into the instance using the provided `name` and `value`.
    ///
    /// - Parameters:
    ///   - name:  The `HTTPHeader` name.
    ///   - value: The `HTTPHeader value.
    public mutating func add(name: String, value: String) {
        headers.append(Header(name: name, value: value))
    }

    /// Case-insensitively updates or appends the provided `HTTPHeader` into the instance.
    ///
    /// - Parameter header: The `HTTPHeader` to update or append.
    public mutating func update(_ header: Header) {
        guard let index = headers.index(of: header.name) else {
            headers.append(header)
            return
        }

        headers.replaceSubrange(index...index, with: [header])
    }
    
    /// Case-insensitively updates or appends the provided `name` and `value` into the headers instance.
    ///
    /// - Parameter header: The `HTTPHeader` to update or append.
    public mutating func update(name: String, value: String) {
        guard let index = headers.index(of: name) else {
            add(name: name, value: value)
            return
        }
        let header = Header(name: name, value: value)
        headers.replaceSubrange(index...index, with: [header])
    }

    /// Case-insensitively removes an `HTTPHeader`, if it exists, from the instance.
    ///
    /// - Parameter name: The name of the `HTTPHeader` to remove.
    public mutating func remove(name: String) {
        guard let index = headers.index(of: name) else { return }

        headers.remove(at: index)
    }

    /// Case-insensitively find a header's value by name.
    ///
    /// - Parameter name: The name of the header to search for, case-insensitively.
    ///
    /// - Returns:        The value of header, if it exists.
    public func value(for name: String) -> String? {
        guard let index = headers.index(of: name) else { return nil }

        return headers[index].value
    }

    /// The dictionary representation of all headers.
    ///
    /// This representation does not preserve the current order of the instance.
    public var dictionary: [String: [String]] {
        let namesAndValues = headers.map { ($0.name, [$0.value]) }

        return Dictionary(namesAndValues) { (first, last) -> [String] in
            return first + last
        }
    }
}

extension Array where Element == Header {
    /// Case-insensitively finds the index of an `HTTPHeader` with the provided name, if it exists.
    func index(of name: String) -> Int? {
        let lowercasedName = name.lowercased()
        return firstIndex { $0.name.lowercased() == lowercasedName }
    }
}

public struct Header {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

extension Headers {
    func toHttpHeaders() -> HttpHeaders {
        let httpHeaders = HttpHeaders()
        
        for header in headers {
            _ = httpHeaders.add(name: header.name, value: header.value)
        }
        return httpHeaders
    }
    
    init(httpHeaders: HttpHeaders) {
        self.init()
        let headers = httpHeaders.getAll()
        headers.forEach { (header) in
            add(name: header.name, value: header.value)
        }
    }
    
    public mutating func addAll(httpHeaders: HttpHeaders) {
        let headers = httpHeaders.getAll()
        headers.forEach { (header) in
            add(name: header.name, value: header.value)
        }
    }
}