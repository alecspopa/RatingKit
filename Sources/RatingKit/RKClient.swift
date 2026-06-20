import Foundation

@MainActor
final class RKClient {
    enum RKError: Error {
        case notConfigured
        case server(code: String, message: String, status: Int)
        case decode(Error)
        case transport(Error)
    }

    private let kit: RatingKit?
    private let session: URLSession

    init(kit: RatingKit, session: URLSession = .shared) {
        self.kit = kit
        self.session = session
    }

    private func post<Body: Encodable, Response: Decodable>(path: String, body: Body) async throws -> Response {
        guard let kit = kit, let config = kit.config else { throw RKError.notConfigured }

        var url = config.apiURL
        url.appendPathComponent(path.hasPrefix("/") ? String(path.dropFirst()) : path)
        
        let bodyData = try JSONEncoder.rk.encode(body)
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let deviceId = kit.storage.deviceId
        let customerFullName = kit.storage.customerFullName

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = bodyData
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue(deviceId, forHTTPHeaderField: "X-Device-Id")
        req.setValue(customerFullName, forHTTPHeaderField: "X-Customer-Full-Name")
        req.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw RKError.transport(error)
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status < 200 || status >= 300 {
            if let err = try? JSONDecoder.rk.decode(RKErrorEnvelope.self, from: data) {
                throw RKError.server(code: err.error.code, message: err.error.message, status: status)
            }
            throw RKError.server(code: "http_\(status)", message: "HTTP \(status)", status: status)
        }

        do {
            return try JSONDecoder.rk.decode(Response.self, from: data)
        } catch {
            throw RKError.decode(error)
        }
    }

    func postRating(rating: RatingBody) async throws {
        let body = RatingEventBody(
            rating: rating.rating,
            feedback: rating.feedback,
            metadata: RKDeviceProbe.snapshot()
        )

        _ = try await post(path: "/api/v1/reviews", body: body) as RKSimpleResponse
    }
}

struct RatingBody: Encodable, Sendable {
    let rating: Int
    let feedback: String
}

private struct RatingEventBody: Encodable, Sendable {
    let rating: Int
    let feedback: String
    let metadata: RKDeviceData
}

private struct RKSimpleResponse: Decodable, Sendable {
    let ok: Bool
}

private struct RKErrorEnvelope: Decodable {
    struct Inner: Decodable { let code: String; let message: String }
    let error: Inner
}

extension JSONEncoder {
    static let rk: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}

extension JSONDecoder {
    static let rk: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
