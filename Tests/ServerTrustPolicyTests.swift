//
//  MultipartFormDataTests.swift
//
//  Copyright (c) 2014-2018 Alamofire Software Foundation (http://alamofire.org/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Alamofire
import Foundation
import XCTest

private struct TestCertificates {
    // Root Certificates
    static let rootCA = TestCertificates.certificateWithFileName("alamofire-root-ca")

    // Intermediate Certificates
    static let intermediateCA1 = TestCertificates.certificateWithFileName("alamofire-signing-ca1")
    static let intermediateCA2 = TestCertificates.certificateWithFileName("alamofire-signing-ca2")

    // Leaf Certificates - Signed by CA1
    static let leafWildcard = TestCertificates.certificateWithFileName("wildcard.alamofire.org")
    static let leafMultipleDNSNames = TestCertificates.certificateWithFileName("multiple-dns-names")
    static let leafSignedByCA1 = TestCertificates.certificateWithFileName("signed-by-ca1")
    static let leafDNSNameAndURI = TestCertificates.certificateWithFileName("test.alamofire.org")

    // Leaf Certificates - Signed by CA2
    static let leafExpired = TestCertificates.certificateWithFileName("expired")
    static let leafMissingDNSNameAndURI = TestCertificates.certificateWithFileName("missing-dns-name-and-uri")
    static let leafSignedByCA2 = TestCertificates.certificateWithFileName("signed-by-ca2")
    static let leafValidDNSName = TestCertificates.certificateWithFileName("valid-dns-name")
    static let leafValidURI = TestCertificates.certificateWithFileName("valid-uri")

    static func certificateWithFileName(_ fileName: String) -> SecCertificate {
        class Locater {}
        let filePath = Bundle(for: Locater.self).path(forResource: fileName, ofType: "cer")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: filePath))
        let certificate = SecCertificateCreateWithData(nil, data as CFData)!

        return certificate
    }
}

// MARK: -

private struct TestPublicKeys {
    // Root Public Keys
    static let rootCA = TestPublicKeys.publicKey(for: TestCertificates.rootCA)

    // Intermediate Public Keys
    static let intermediateCA1 = TestPublicKeys.publicKey(for: TestCertificates.intermediateCA1)
    static let intermediateCA2 = TestPublicKeys.publicKey(for: TestCertificates.intermediateCA2)

    // Leaf Public Keys - Signed by CA1
    static let leafWildcard = TestPublicKeys.publicKey(for: TestCertificates.leafWildcard)
    static let leafMultipleDNSNames = TestPublicKeys.publicKey(for: TestCertificates.leafMultipleDNSNames)
    static let leafSignedByCA1 = TestPublicKeys.publicKey(for: TestCertificates.leafSignedByCA1)
    static let leafDNSNameAndURI = TestPublicKeys.publicKey(for: TestCertificates.leafDNSNameAndURI)

    // Leaf Public Keys - Signed by CA2
    static let leafExpired = TestPublicKeys.publicKey(for: TestCertificates.leafExpired)
    static let leafMissingDNSNameAndURI = TestPublicKeys.publicKey(for: TestCertificates.leafMissingDNSNameAndURI)
    static let leafSignedByCA2 = TestPublicKeys.publicKey(for: TestCertificates.leafSignedByCA2)
    static let leafValidDNSName = TestPublicKeys.publicKey(for: TestCertificates.leafValidDNSName)
    static let leafValidURI = TestPublicKeys.publicKey(for: TestCertificates.leafValidURI)

    static func publicKey(for certificate: SecCertificate) -> SecKey {
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        SecTrustCreateWithCertificates(certificate, policy, &trust)

        let publicKey = SecTrustCopyPublicKey(trust!)!

        return publicKey
    }
}

// MARK: -

private enum TestTrusts {
    // Leaf Trusts - Signed by CA1
    case leafWildcard
    case leafMultipleDNSNames
    case leafSignedByCA1
    case leafDNSNameAndURI

    // Leaf Trusts - Signed by CA2
    case leafExpired
    case leafMissingDNSNameAndURI
    case leafSignedByCA2
    case leafValidDNSName
    case leafValidURI

    // Invalid Trusts
    case leafValidDNSNameMissingIntermediate
    case leafValidDNSNameWithIncorrectIntermediate

    var trust: SecTrust {
        let trust: SecTrust

        switch self {
        case .leafWildcard:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.leafWildcard,
                TestCertificates.intermediateCA1,
                TestCertificates.rootCA
            ])
        case .leafMultipleDNSNames:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.leafMultipleDNSNames,
                TestCertificates.intermediateCA1,
                TestCertificates.rootCA
            ])
        case .leafSignedByCA1:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.leafSignedByCA1,
                TestCertificates.intermediateCA1,
                TestCertificates.rootCA
            ])
        case .leafDNSNameAndURI:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.leafDNSNameAndURI,
                TestCertificates.intermediateCA1,
                TestCertificates.rootCA
            ])
        case .leafExpired:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.leafExpired,
                TestCertificates.intermediateCA2,
                TestCertificates.rootCA
            ])
        case .leafMissingDNSNameAndURI:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.leafMissingDNSNameAndURI,
                TestCertificates.intermediateCA2,
                TestCertificates.rootCA
            ])
        case .leafSignedByCA2:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.leafSignedByCA2,
                TestCertificates.intermediateCA2,
                TestCertificates.rootCA
            ])
        case .leafValidDNSName:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.leafValidDNSName,
                TestCertificates.intermediateCA2,
                TestCertificates.rootCA
            ])
        case .leafValidURI:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.leafValidURI,
                TestCertificates.intermediateCA2,
                TestCertificates.rootCA
            ])
        case .leafValidDNSNameMissingIntermediate:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.leafValidDNSName,
                TestCertificates.rootCA
            ])
        case .leafValidDNSNameWithIncorrectIntermediate:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.leafValidDNSName,
                TestCertificates.intermediateCA1,
                TestCertificates.rootCA
            ])
        }

        return trust
    }

    static func trustWithCertificates(_ certificates: [SecCertificate]) -> SecTrust {
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        SecTrustCreateWithCertificates(certificates as CFTypeRef, policy, &trust)

        return trust!
    }
}

// MARK: - Basic X509 and SSL Exploration Tests -

class ServerTrustPolicyTestCase: BaseTestCase {
    func setRootCertificateAsLoneAnchorCertificateForTrust(_ trust: SecTrust) {
        SecTrustSetAnchorCertificates(trust, [TestCertificates.rootCA] as CFArray)
        SecTrustSetAnchorCertificatesOnly(trust, true)
    }

    func trustIsValid(_ trust: SecTrust) -> Bool {
        var isValid = false
        var result = SecTrustResultType.invalid

        let status = SecTrustEvaluate(trust, &result)

        if status == errSecSuccess {
            let unspecified = SecTrustResultType.unspecified
            let proceed = SecTrustResultType.proceed

            isValid = result == unspecified || result == proceed
        }

        return isValid
    }
}

// MARK: -

class ServerTrustPolicyExplorationBasicX509PolicyValidationTestCase: ServerTrustPolicyTestCase {
    func testThatAnchoredRootCertificatePassesBasicX509ValidationWithRootInTrust() {
        // Given
        let trust = TestTrusts.trustWithCertificates([
            TestCertificates.leafDNSNameAndURI,
            TestCertificates.intermediateCA1,
            TestCertificates.rootCA
        ])

        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateBasicX509()]
        SecTrustSetPolicies(trust, policies as CFTypeRef)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should be valid")
    }

    func testThatAnchoredRootCertificatePassesBasicX509ValidationWithoutRootInTrust() {
        // Given
        let trust = TestTrusts.leafDNSNameAndURI.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateBasicX509()]
        SecTrustSetPolicies(trust, policies as CFTypeRef)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should be valid")
    }

    func testThatCertificateMissingDNSNamePassesBasicX509Validation() {
        // Given
        let trust = TestTrusts.leafMissingDNSNameAndURI.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateBasicX509()]
        SecTrustSetPolicies(trust, policies as CFTypeRef)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should be valid")
    }

    func testThatExpiredCertificateFailsBasicX509Validation() {
        // Given
        let trust = TestTrusts.leafExpired.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateBasicX509()]
        SecTrustSetPolicies(trust, policies as CFTypeRef)

        // Then
        XCTAssertFalse(trustIsValid(trust), "trust should not be valid")
    }
}

// MARK: -

class ServerTrustPolicyExplorationSSLPolicyValidationTestCase: ServerTrustPolicyTestCase {
    func testThatAnchoredRootCertificatePassesSSLValidationWithRootInTrust() {
        // Given
        let trust = TestTrusts.trustWithCertificates([
            TestCertificates.leafDNSNameAndURI,
            TestCertificates.intermediateCA1,
            TestCertificates.rootCA
        ])

        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateSSL(true, "test.alamofire.org" as CFString)]
        SecTrustSetPolicies(trust, policies as CFTypeRef)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should be valid")
    }

    func testThatAnchoredRootCertificatePassesSSLValidationWithoutRootInTrust() {
        // Given
        let trust = TestTrusts.leafDNSNameAndURI.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateSSL(true, "test.alamofire.org" as CFString)]
        SecTrustSetPolicies(trust, policies as CFTypeRef)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should be valid")
    }

    func testThatCertificateMissingDNSNameFailsSSLValidation() {
        // Given
        let trust = TestTrusts.leafMissingDNSNameAndURI.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateSSL(true, "test.alamofire.org" as CFString)]
        SecTrustSetPolicies(trust, policies as CFTypeRef)

        // Then
        XCTAssertFalse(trustIsValid(trust), "trust should not be valid")
    }

    func testThatWildcardCertificatePassesSSLValidation() {
        // Given
        let trust = TestTrusts.leafWildcard.trust // *.alamofire.org
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateSSL(true, "test.alamofire.org" as CFString)]
        SecTrustSetPolicies(trust, policies as CFTypeRef)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should be valid")
    }

    func testThatDNSNameCertificatePassesSSLValidation() {
        // Given
        let trust = TestTrusts.leafValidDNSName.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateSSL(true, "test.alamofire.org" as CFString)]
        SecTrustSetPolicies(trust, policies as CFTypeRef)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should be valid")
    }

    func testThatURICertificateFailsSSLValidation() {
        // Given
        let trust = TestTrusts.leafValidURI.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateSSL(true, "test.alamofire.org" as CFString)]
        SecTrustSetPolicies(trust, policies as CFTypeRef)

        // Then
        XCTAssertFalse(trustIsValid(trust), "trust should not be valid")
    }

    func testThatMultipleDNSNamesCertificatePassesSSLValidationForAllEntries() {
        // Given
        let trust = TestTrusts.leafMultipleDNSNames.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [
            SecPolicyCreateSSL(true, "test.alamofire.org" as CFString),
            SecPolicyCreateSSL(true, "blog.alamofire.org" as CFString),
            SecPolicyCreateSSL(true, "www.alamofire.org" as CFString)
        ]
        SecTrustSetPolicies(trust, policies as CFTypeRef)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should not be valid")
    }

    func testThatPassingNilForHostParameterAllowsCertificateMissingDNSNameToPassSSLValidation() {
        // Given
        let trust = TestTrusts.leafMissingDNSNameAndURI.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateSSL(true, nil)]
        SecTrustSetPolicies(trust, policies as CFTypeRef)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should not be valid")
    }

    func testThatExpiredCertificateFailsSSLValidation() {
        // Given
        let trust = TestTrusts.leafExpired.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateSSL(true, "test.alamofire.org" as CFString)]
        SecTrustSetPolicies(trust, policies as CFTypeRef)

        // Then
        XCTAssertFalse(trustIsValid(trust), "trust should not be valid")
    }
}

// MARK: - Server Trust Policy Tests -

class ServerTrustPolicyPerformDefaultEvaluationTestCase: ServerTrustPolicyTestCase {

    // MARK: Do NOT Validate Host

    func testThatValidCertificateChainPassesEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let serverTrustPolicy = DefaultTrustEvaluator(validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatNonAnchoredRootCertificateChainFailsEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.trustWithCertificates([
            TestCertificates.leafValidDNSName,
            TestCertificates.intermediateCA2
        ])
        let serverTrustPolicy = DefaultTrustEvaluator(validateHost: false)

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatMissingDNSNameLeafCertificatePassesEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafMissingDNSNameAndURI.trust
        let serverTrustPolicy = DefaultTrustEvaluator(validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatExpiredCertificateChainFailsEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let serverTrustPolicy = DefaultTrustEvaluator(validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatMissingIntermediateCertificateInChainFailsEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSNameMissingIntermediate.trust
        let serverTrustPolicy = DefaultTrustEvaluator(validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    // MARK: Validate Host

    func testThatValidCertificateChainPassesEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let serverTrustPolicy = DefaultTrustEvaluator(validateHost: true)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatNonAnchoredRootCertificateChainFailsEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.trustWithCertificates([
            TestCertificates.leafValidDNSName,
            TestCertificates.intermediateCA2
        ])
        let serverTrustPolicy = DefaultTrustEvaluator(validateHost: true)

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatMissingDNSNameLeafCertificateFailsEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafMissingDNSNameAndURI.trust
        let serverTrustPolicy = DefaultTrustEvaluator(validateHost: true)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatWildcardedLeafCertificateChainPassesEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafWildcard.trust
        let serverTrustPolicy = DefaultTrustEvaluator(validateHost: true)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatExpiredCertificateChainFailsEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let serverTrustPolicy = DefaultTrustEvaluator(validateHost: true)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatMissingIntermediateCertificateInChainFailsEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSNameMissingIntermediate.trust
        let serverTrustPolicy = DefaultTrustEvaluator(validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let result = Result { try serverTrustPolicy.evaluate(serverTrust, forHost: host) }

        // Then
        XCTAssertFalse(result.isSuccess, "server trust should not pass evaluation")
        AssertErrorIsAFError(result.error) { (error) in
            XCTAssertTrue(error.isServerTrustEvaluationError)
        }
    }
}

// MARK: -

class ServerTrustPolicyPerformRevokedEvaluationTestCase: ServerTrustPolicyTestCase {

    // MARK: Do NOT Validate Host

    func testThatValidCertificateChainPassesEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let serverTrustPolicy = RevocationTrustEvaluator(validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatNonAnchoredRootCertificateChainFailsEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.trustWithCertificates([
            TestCertificates.leafValidDNSName,
            TestCertificates.intermediateCA2
        ])
        let serverTrustPolicy = RevocationTrustEvaluator(validateHost: false)

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatMissingDNSNameLeafCertificatePassesEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafMissingDNSNameAndURI.trust
        let serverTrustPolicy = RevocationTrustEvaluator(validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatExpiredCertificateChainFailsEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let serverTrustPolicy = RevocationTrustEvaluator(validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatMissingIntermediateCertificateInChainFailsEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSNameMissingIntermediate.trust
        let serverTrustPolicy = RevocationTrustEvaluator(validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    // MARK: Validate Host

    func testThatValidCertificateChainPassesEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let serverTrustPolicy = RevocationTrustEvaluator()

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatNonAnchoredRootCertificateChainFailsEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.trustWithCertificates([
            TestCertificates.leafValidDNSName,
            TestCertificates.intermediateCA2
        ])
        let serverTrustPolicy = RevocationTrustEvaluator()

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatMissingDNSNameLeafCertificateFailsEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafMissingDNSNameAndURI.trust
        let serverTrustPolicy = RevocationTrustEvaluator()

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatWildcardedLeafCertificateChainPassesEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafWildcard.trust
        let serverTrustPolicy = RevocationTrustEvaluator()

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatExpiredCertificateChainFailsEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let serverTrustPolicy = RevocationTrustEvaluator()

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatMissingIntermediateCertificateInChainFailsEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSNameMissingIntermediate.trust
        let serverTrustPolicy = RevocationTrustEvaluator()

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }
}

// MARK: -

class ServerTrustPolicyPinCertificatesTestCase: ServerTrustPolicyTestCase {

    // MARK: Validate Certificate Chain Without Validating Host

    func testThatPinnedLeafCertificatePassesEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.leafValidDNSName]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(certificates: certificates, validateHost: false)

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinnedIntermediateCertificatePassesEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.intermediateCA2]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(certificates: certificates, validateHost: false)

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinnedRootCertificatePassesEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.rootCA]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(certificates: certificates, validateHost: false)

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningLeafCertificateNotInCertificateChainFailsEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.leafSignedByCA2]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(
            certificates: certificates,
            validateCertificateChain: true,
            validateHost: false
        )

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningIntermediateCertificateNotInCertificateChainFailsEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.intermediateCA1]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(certificates: certificates, validateHost: false)

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningExpiredLeafCertificateFailsEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let certificates = [TestCertificates.leafExpired]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(certificates: certificates, validateHost: false)

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningIntermediateCertificateWithExpiredLeafCertificateFailsEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let certificates = [TestCertificates.intermediateCA2]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(certificates: certificates, validateHost: false)

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    // MARK: Validate Certificate Chain and Host

    func testThatPinnedLeafCertificatePassesEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.leafValidDNSName]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(certificates: certificates)

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinnedIntermediateCertificatePassesEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.intermediateCA2]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(certificates: certificates)

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinnedRootCertificatePassesEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.rootCA]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(certificates: certificates)

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningLeafCertificateNotInCertificateChainFailsEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.leafSignedByCA2]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(
            certificates: certificates,
            validateCertificateChain: true,
            validateHost: true
        )

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningIntermediateCertificateNotInCertificateChainFailsEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.intermediateCA1]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(certificates: certificates)

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningExpiredLeafCertificateFailsEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let certificates = [TestCertificates.leafExpired]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(certificates: certificates)

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningIntermediateCertificateWithExpiredLeafCertificateFailsEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let certificates = [TestCertificates.intermediateCA2]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(certificates: certificates)

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    // MARK: Do NOT Validate Certificate Chain or Host

    func testThatPinnedLeafCertificateWithoutCertificateChainValidationPassesEvaluation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.leafValidDNSName]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinnedIntermediateCertificateWithoutCertificateChainValidationPassesEvaluation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.intermediateCA2]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinnedRootCertificateWithoutCertificateChainValidationPassesEvaluation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.rootCA]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningLeafCertificateNotInCertificateChainWithoutCertificateChainValidationFailsEvaluation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.leafSignedByCA2]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningIntermediateCertificateNotInCertificateChainWithoutCertificateChainValidationFailsEvaluation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.intermediateCA1]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningExpiredLeafCertificateWithoutCertificateChainValidationPassesEvaluation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let certificates = [TestCertificates.leafExpired]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningIntermediateCertificateWithExpiredLeafCertificateWithoutCertificateChainValidationPassesEvaluation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let certificates = [TestCertificates.intermediateCA2]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningRootCertificateWithExpiredLeafCertificateWithoutCertificateChainValidationPassesEvaluation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let certificates = [TestCertificates.rootCA]
        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningMultipleCertificatesWithoutCertificateChainValidationPassesEvaluation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust

        let certificates = [
            TestCertificates.leafMultipleDNSNames, // not in certificate chain
            TestCertificates.leafSignedByCA1,      // not in certificate chain
            TestCertificates.leafExpired,          // in certificate chain 👍🏼👍🏼
            TestCertificates.leafWildcard,         // not in certificate chain
            TestCertificates.leafDNSNameAndURI,    // not in certificate chain
        ]

        let serverTrustPolicy = PinnedCertificatesTrustEvaluator(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }
}

// MARK: -

class ServerTrustPolicyPinPublicKeysTestCase: ServerTrustPolicyTestCase {

    // MARK: Validate Certificate Chain Without Validating Host

    func testThatPinningLeafKeyPassesEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.leafValidDNSName]
        let serverTrustPolicy = PublicKeysTrustEvaluator(keys: publicKeys, validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningIntermediateKeyPassesEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.intermediateCA2]
        let serverTrustPolicy = PublicKeysTrustEvaluator(keys: publicKeys, validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningRootKeyPassesEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.rootCA]
        let serverTrustPolicy = PublicKeysTrustEvaluator(keys: publicKeys, validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningKeyNotInCertificateChainFailsEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.leafSignedByCA2]
        let serverTrustPolicy = PublicKeysTrustEvaluator(keys: publicKeys, validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningBackupKeyPassesEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.leafSignedByCA1, TestPublicKeys.intermediateCA1, TestPublicKeys.leafValidDNSName]
        let serverTrustPolicy = PublicKeysTrustEvaluator(keys: publicKeys, validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    // MARK: Validate Certificate Chain and Host

    func testThatPinningLeafKeyPassesEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.leafValidDNSName]
        let serverTrustPolicy = PublicKeysTrustEvaluator(keys: publicKeys)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningIntermediateKeyPassesEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.intermediateCA2]
        let serverTrustPolicy = PublicKeysTrustEvaluator(keys: publicKeys)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningRootKeyPassesEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.rootCA]
        let serverTrustPolicy = PublicKeysTrustEvaluator(keys: publicKeys)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningKeyNotInCertificateChainFailsEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.leafSignedByCA2]
        let serverTrustPolicy = PublicKeysTrustEvaluator(keys: publicKeys)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningBackupKeyPassesEvaluationWithHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.leafSignedByCA1, TestPublicKeys.intermediateCA1, TestPublicKeys.leafValidDNSName]
        let serverTrustPolicy = PublicKeysTrustEvaluator(keys: publicKeys)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    // MARK: Do NOT Validate Certificate Chain or Host

    func testThatPinningLeafKeyWithoutCertificateChainValidationPassesEvaluationWithMissingIntermediateCertificate() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSNameMissingIntermediate.trust
        let publicKeys = [TestPublicKeys.leafValidDNSName]
        let serverTrustPolicy = PublicKeysTrustEvaluator(
            keys: publicKeys,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningRootKeyWithoutCertificateChainValidationFailsEvaluationWithMissingIntermediateCertificate() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSNameMissingIntermediate.trust
        let publicKeys = [TestPublicKeys.rootCA]
        let serverTrustPolicy = PublicKeysTrustEvaluator(
            keys: publicKeys,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningLeafKeyWithoutCertificateChainValidationPassesEvaluationWithIncorrectIntermediateCertificate() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSNameWithIncorrectIntermediate.trust
        let publicKeys = [TestPublicKeys.leafValidDNSName]
        let serverTrustPolicy = PublicKeysTrustEvaluator(
            keys: publicKeys,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningLeafKeyWithoutCertificateChainValidationPassesEvaluationWithExpiredLeafCertificate() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let publicKeys = [TestPublicKeys.leafExpired]
        let serverTrustPolicy = PublicKeysTrustEvaluator(
            keys: publicKeys,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningIntermediateKeyWithoutCertificateChainValidationPassesEvaluationWithExpiredLeafCertificate() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let publicKeys = [TestPublicKeys.intermediateCA2]
        let serverTrustPolicy = PublicKeysTrustEvaluator(
            keys: publicKeys,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningRootKeyWithoutCertificateChainValidationPassesEvaluationWithExpiredLeafCertificate() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let publicKeys = [TestPublicKeys.rootCA]
        let serverTrustPolicy = PublicKeysTrustEvaluator(
            keys: publicKeys,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }
}

// MARK: -

class ServerTrustPolicyDisableEvaluationTestCase: ServerTrustPolicyTestCase {
    func testThatCertificateChainMissingIntermediateCertificatePassesEvaluation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSNameMissingIntermediate.trust
        let serverTrustPolicy = DisabledEvaluator()

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatExpiredLeafCertificatePassesEvaluation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let serverTrustPolicy = DisabledEvaluator()

        // When
        let serverTrustIsValid = try serverTrustPolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }
}

// MARK: -

class ServerTrustPolicyCompositeTestCase: ServerTrustPolicyTestCase {
    func testThatValidCertificateChainPassesDefaultAndRevocationCompositeChecks() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let defaultPolicy = DefaultTrustEvaluator(validateHost: false)
        let revocationPolicy = RevocationTrustEvaluator(validateHost: false)
        let compositePolicy = CompositeTrustEvaluator(evaluators: [defaultPolicy, revocationPolicy])

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try compositePolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatNonAnchoredRootCertificateChainFailsEvaluationWithoutHostValidation() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.trustWithCertificates([
            TestCertificates.leafValidDNSName,
            TestCertificates.intermediateCA2
            ])
        let defaultPolicy = DefaultTrustEvaluator(validateHost: false)
        let revocationPolicy = RevocationTrustEvaluator(validateHost: false)
        let compositePolicy = CompositeTrustEvaluator(evaluators: [defaultPolicy, revocationPolicy])

        // When
        XCTAssertThrowsError(try compositePolicy.evaluate(serverTrust, forHost: host),
                             "server trust should not pass evaluation") { (error) in
            XCTAssertEqual((error.asAFError)?.isServerTrustEvaluationError, true)
        }
//        let serverTrustIsValid = try compositePolicy.evaluate(serverTrust, forHost: host)
//
//        // Then
//        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatExpiredLeafCertificateFailsDefaultAndRevocationComposite() throws {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let defaultPolicy = DefaultTrustEvaluator(validateHost: false)
        let revocationPolicy = RevocationTrustEvaluator(validateHost: false)
        let compositePolicy = CompositeTrustEvaluator(evaluators: [defaultPolicy, revocationPolicy])

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = try compositePolicy.evaluate(serverTrust, forHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }
}

// MARK: -

class ServerTrustPolicyCertificatesInBundleTestCase: ServerTrustPolicyTestCase {
    func testOnlyValidCertificatesAreDetected() {
        // Given
        // Files present in bundle in the form of type+encoding+extension [key|cert][DER|PEM].[cer|crt|der|key|pem]
        // certDER.cer: DER-encoded well-formed certificate
        // certDER.crt: DER-encoded well-formed certificate
        // certDER.der: DER-encoded well-formed certificate
        // certPEM.*: PEM-encoded well-formed certificates, expected to fail: Apple API only handles DER encoding
        // devURandomGibberish.crt: Random data, should fail
        // keyDER.der: DER-encoded key, not a certificate, should fail

        // When
        let certificates = Bundle(for: ServerTrustPolicyCertificatesInBundleTestCase.self).certificates

        // Then
        // Expectation: 19 well-formed certificates in the test bundle plus 4 invalid certificates.
        #if os(macOS)
            // For some reason, macOS is allowing all certificates to be considered valid. Need to file a
            // rdar demonstrating this behavior.
            if #available(OSX 10.12, *) {
                XCTAssertEqual(certificates.count, 19, "Expected 19 well-formed certificates")
            } else {
                XCTAssertEqual(certificates.count, 23, "Expected 23 well-formed certificates")
            }
        #else
            XCTAssertEqual(certificates.count, 19, "Expected 19 well-formed certificates")
        #endif
    }
}
