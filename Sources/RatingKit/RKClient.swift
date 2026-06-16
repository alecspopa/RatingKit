//
//  RKClient.swift
//  RatingKit
//
//  Created by Alecs Popa on 16.06.26.
//

import Foundation
import CryptoKit

/// URLSession-backed HTTP client. Handles the per-request signing + auth
/// headers so individual endpoints don't have to.
///
/// Auth scheme (matches www/include/api.php):
///     X-API-Key:    <api_key>
///     X-Device-Id:  <uuid>
///     X-Timestamp:  <unix seconds>
///     X-Signature:  sha256(api_secret + device_id + timestamp + body)
///
/// Decompiling the host app can leak the secret.
/// The signature mainly stops casual abuse from network-trace observers.
@MainActor
final class RKClient {

    private weak var kit: RatingKit?
    private let session: URLSession

    init(kit: RatingKit, session: URLSession = .shared) {
        self.kit = kit
        self.session = session
    }

    enum RKError: Error {
        case notConfigured
        case server(code: String, message: String, status: Int)
        case decode(Error)
        case transport(Error)
    }

    func post<B: Encodable, R: Decodable>(path: String, body: B) async throws -> R {
        guard let kit = kit, let config = kit.config else { throw RKError.notConfigured }

        let bodyData = try JSONEncoder.rk.encode(body)
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let deviceId = kit.storage.deviceId

        let bodyString = String(data: bodyData, encoding: .utf8) ?? ""
        let signaturePayload = config.apiSecret + deviceId + timestamp + bodyString
        let signature = SHA256.hash(data: Data(signaturePayload.utf8))
            .map { String(format: "%02x", $0) }
            .joined()

        var url = kit.baseURL
        url.appendPathComponent(path.hasPrefix("/") ? String(path.dropFirst()) : path)

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = bodyData
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
        req.setValue(deviceId,      forHTTPHeaderField: "X-Device-Id")
        req.setValue(timestamp,     forHTTPHeaderField: "X-Timestamp")
        req.setValue(signature,     forHTTPHeaderField: "X-Signature")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw RKError.transport(error)
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status < 200 || status >= 300 {
            if let err = try? JSONDecoder.rk.decode(AFPErrorEnvelope.self, from: data) {
                throw RKError.server(code: err.error.code, message: err.error.message, status: status)
            }
            throw RKError.server(code: "http_\(status)", message: "HTTP \(status)", status: status)
        }

        do {
            return try JSONDecoder.rk.decode(R.self, from: data)
        } catch {
            throw RKError.decode(error)
        }
    }
}

private struct AFPErrorEnvelope: Decodable {
    struct Inner: Decodable { let code: String; let message: String }
    let error: Inner
}

extension JSONEncoder {
    static let rk: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}

extension JSONDecoder {
    static let rk: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
