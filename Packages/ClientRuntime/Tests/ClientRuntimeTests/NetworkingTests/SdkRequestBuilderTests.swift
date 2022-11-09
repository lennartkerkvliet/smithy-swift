/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
import AwsCommonRuntimeKit
@testable import ClientRuntime

class SdkRequestBuilderTests: XCTestCase {
    func testSdkRequestBuilderUpdate() {
        let url = "https://stehlibstoragebucket144955-dev.s3.us-east-1.amazonaws.com/public/README.md?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAVIBY7SZR4C4MBGAW%2F20220225%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20220225T034419Z&X-Amz-Expires=17999&X-Amz-SignedHeaders=host&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEEQaCXVzLWVhc3QtMSJHMEUCIEKUDdnCf1h3cZNdv10q6G24zLgn0r6th4m%2FXSS9TuR4AiEAwOwf2cG%2F1W%2FkAz1UMqFW9sZp7SY6j%2BmiicLy1dB8OXUqmgYInf%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARABGgwzNjA4OTY3NjM0OTEiDH6CiNUJiwL4sNy9KCruBbdJnGSx88A%2Be0SBpKEpSurxunasaDsJb2ZJPqVhC%2FcKPr87PYcp5BrnkGumcYhUAEknVbHACLLUx2%2Fnzfacp13PHmclSsLe52qGwjFFVMz0m41PV3HiCoHgIc7vVIHnwNySaX9ZJbVowhNvI4V9eixVKhjjx7Tqku1bsOzlq9dJP15qz8FVNjlKGjZFqrMGTzpTgmS9dNPqphwCcxx306RLUd35SEvXjxnWcidOdddYQs9j4wu47DOM8ftveag6cDptJQN71dDIRHgFTisVshD78Rm9pycKf3g0QvBAGtrzhcxUcJtNgIWv%2B10hsEBURsEYommcjI8vT1yX2K8pLVOxgL%2FRWXndbAeIzAu5vmLm6RqkfGwkHQPQl7uII6YzL2Gku%2FMDilVFw9TBKIg6KDP9l2GzzVRQsvLMpFIp%2Bx3a1s4OVduJRFpDYCwEsfKhIoVkb610gBbFayPKjQVcZfULdq1r5DOZzpHVDoijnKHAxHtFgaFPP6KtG%2BmdKeix8gccdbsdgMokWKtJhisFo%2BzLn02oSSX4ITkZKzZcriGxQO4E1YUlYyBhjlCg1b74faQfWstk24PrkCfNXYcQ5oxgglIA0tBOdOfwGn2Je3MBEj2T8Yz0GS%2BZib3DKVWRzU0Xk9pwDXH3iaBn9Uld%2BNyw9gxdOCBVKtTILtdfsjw9lJSVOJomlJn1h8gH96PToBg9lOc4ms6aA2Z%2FoN%2F3UV%2Beo5%2FpB9xfMkBIeOg6vAI0VtjkUhH052UouEKU%2BVGSGuCSuVzZmIBJLWHZaQUJZ3hJCdGqM%2FoM4Ud51Cidcnr%2Bni%2Bgp4RAfg0gvX6Eb2e%2FNMqNd0Eg7ftmnPXzQR3ZVC1yyNFu2kBt8icKdMnkLZT8YO1Racd1QgrZ5DZJlU%2FS2eisLGSTMb9Dmaq8AGbxgGK55acIvsQLzvJhavFWbh%2FyNudQBSLC0c5BZGxQk2J%2BJx%2FlR5wR%2B0gXOfTg5EImMrLzh7gOo56i2Rhj2xRFSDDDnuGQBjqHArU56DsGZNeKwkVK87lVJAfiAsWmKaDlBNXcuhKl084syaZMiVUQa7dPupgeg%2BvVPv4dAwNULjuE3B7V5lSea4RIDOfGwTtlj4Ekn3t4PrlxHpEyMeuRgekNhpdcfL5pgRcKH4AKgqI7fCrghhH1qDMTpUkORRv6EwPGqM0LPm93XPVOjrG3EJ5ZOYLJM05bbrcalzN0mbSbsRrcphme7Z8zpD5jNeSWdBhWA04DQ7RZuJpqFnn40yKq7G8kgtLmOJGRs7CGTWT9on7EOpH3RdKGPXL06%2BgLo7r9%2Fdkb%2BHGJF6spjqbH0SN%2FySjnvgNL1NrGAy%2FQgPwfDw6oJ6TPNdH8dfM8tmdd&X-Amz-Signature=90b9f3353ad4f2596fdd166c00da8fb86d5d255bf3c8b296c5e5a7db25fd41aa"
        let pathToMatch = "/public/README.md?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAVIBY7SZR4C4MBGAW%2F20220225%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20220225T034419Z&X-Amz-Expires=17999&X-Amz-SignedHeaders=host&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEEQaCXVzLWVhc3QtMSJHMEUCIEKUDdnCf1h3cZNdv10q6G24zLgn0r6th4m%2FXSS9TuR4AiEAwOwf2cG%2F1W%2FkAz1UMqFW9sZp7SY6j%2BmiicLy1dB8OXUqmgYInf%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARABGgwzNjA4OTY3NjM0OTEiDH6CiNUJiwL4sNy9KCruBbdJnGSx88A%2Be0SBpKEpSurxunasaDsJb2ZJPqVhC%2FcKPr87PYcp5BrnkGumcYhUAEknVbHACLLUx2%2Fnzfacp13PHmclSsLe52qGwjFFVMz0m41PV3HiCoHgIc7vVIHnwNySaX9ZJbVowhNvI4V9eixVKhjjx7Tqku1bsOzlq9dJP15qz8FVNjlKGjZFqrMGTzpTgmS9dNPqphwCcxx306RLUd35SEvXjxnWcidOdddYQs9j4wu47DOM8ftveag6cDptJQN71dDIRHgFTisVshD78Rm9pycKf3g0QvBAGtrzhcxUcJtNgIWv%2B10hsEBURsEYommcjI8vT1yX2K8pLVOxgL%2FRWXndbAeIzAu5vmLm6RqkfGwkHQPQl7uII6YzL2Gku%2FMDilVFw9TBKIg6KDP9l2GzzVRQsvLMpFIp%2Bx3a1s4OVduJRFpDYCwEsfKhIoVkb610gBbFayPKjQVcZfULdq1r5DOZzpHVDoijnKHAxHtFgaFPP6KtG%2BmdKeix8gccdbsdgMokWKtJhisFo%2BzLn02oSSX4ITkZKzZcriGxQO4E1YUlYyBhjlCg1b74faQfWstk24PrkCfNXYcQ5oxgglIA0tBOdOfwGn2Je3MBEj2T8Yz0GS%2BZib3DKVWRzU0Xk9pwDXH3iaBn9Uld%2BNyw9gxdOCBVKtTILtdfsjw9lJSVOJomlJn1h8gH96PToBg9lOc4ms6aA2Z%2FoN%2F3UV%2Beo5%2FpB9xfMkBIeOg6vAI0VtjkUhH052UouEKU%2BVGSGuCSuVzZmIBJLWHZaQUJZ3hJCdGqM%2FoM4Ud51Cidcnr%2Bni%2Bgp4RAfg0gvX6Eb2e%2FNMqNd0Eg7ftmnPXzQR3ZVC1yyNFu2kBt8icKdMnkLZT8YO1Racd1QgrZ5DZJlU%2FS2eisLGSTMb9Dmaq8AGbxgGK55acIvsQLzvJhavFWbh%2FyNudQBSLC0c5BZGxQk2J%2BJx%2FlR5wR%2B0gXOfTg5EImMrLzh7gOo56i2Rhj2xRFSDDDnuGQBjqHArU56DsGZNeKwkVK87lVJAfiAsWmKaDlBNXcuhKl084syaZMiVUQa7dPupgeg%2BvVPv4dAwNULjuE3B7V5lSea4RIDOfGwTtlj4Ekn3t4PrlxHpEyMeuRgekNhpdcfL5pgRcKH4AKgqI7fCrghhH1qDMTpUkORRv6EwPGqM0LPm93XPVOjrG3EJ5ZOYLJM05bbrcalzN0mbSbsRrcphme7Z8zpD5jNeSWdBhWA04DQ7RZuJpqFnn40yKq7G8kgtLmOJGRs7CGTWT9on7EOpH3RdKGPXL06%2BgLo7r9%2Fdkb%2BHGJF6spjqbH0SN%2FySjnvgNL1NrGAy%2FQgPwfDw6oJ6TPNdH8dfM8tmdd&X-Amz-Signature=90b9f3353ad4f2596fdd166c00da8fb86d5d255bf3c8b296c5e5a7db25fd41aa"
        let queryItems = [URLQueryItem(name: "Bucket", value: "stehlibstoragebucket144955-dev"), URLQueryItem(name: "Key", value: "public%2FREADME.md")]
        let originalRequest = SdkHttpRequest(method: .get, endpoint: Endpoint(host: "stehlibstoragebucket144955-dev.s3.us-east-1.amazonaws.com", path: "/", port: 80, queryItems: queryItems, protocolType: .https), headers: Headers())
        let crtRequest = HttpRequest()
        crtRequest.path = pathToMatch
        
        let updatedRequest = SdkHttpRequestBuilder().update(from: crtRequest, originalRequest: originalRequest).build()
        let updatedPath = updatedRequest.endpoint.path + updatedRequest.endpoint.queryItemString
        XCTAssertEqual(pathToMatch, updatedPath)
        XCTAssertEqual(url, updatedRequest.endpoint.url?.absoluteString)
    }

    func testBuildWSSRequest() {
        let protocolType = ProtocolType.wss
        let host = "foo.us-east-1.amazonaws.com"
        let path = "/hello-world"
        let queryItem = (name: "bar", value: "baz")
        let request = SdkHttpRequestBuilder()
            .withProtocol(protocolType)
            .withHost(host)
            .withPath(path)
            .withQueryItem(.init(name: queryItem.name, value: queryItem.value))
            .build()

        let expectedOutput = "\(protocolType.rawValue)://\(host)\(path)?\(queryItem.name)=\(queryItem.value)"

        XCTAssertEqual(request.endpoint.url?.absoluteString, expectedOutput)
    }
}
