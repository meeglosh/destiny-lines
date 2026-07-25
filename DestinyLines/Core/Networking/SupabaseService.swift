import Foundation
import Supabase

/// Thin wrapper around supabase-swift: anonymous auth, Edge Function calls, readings fetch.
/// All privileged work (OpenAI, R2, entitlement writes) happens in Edge Functions; the app
/// only ever holds the anon key (CLAUDE.md §1).
final class SupabaseService: Sendable {
    static let shared = SupabaseService()

    private let client: SupabaseClient

    private init() {
        client = SupabaseClient(supabaseURL: SupabaseConfig.url, supabaseKey: SupabaseConfig.anonKey)
    }

    // MARK: - Auth

    /// Ensure a session exists, signing in anonymously on first launch (§3).
    func ensureSession() async throws {
        if let session = try? await client.auth.session, !session.isExpired {
            return
        }
        _ = try await client.auth.signInAnonymously()
    }

    var userID: UUID? {
        get async { try? await client.auth.session.user.id }
    }

    // MARK: - Reading pipeline

    struct UploadSlot: Decodable {
        let uploadURL: URL
        let objectKey: String
    }

    /// Ask request-upload for a presigned PUT slot.
    func requestUploadSlot() async throws -> UploadSlot {
        try await client.functions.invoke("request-upload")
    }

    /// PUT the JPEG straight to R2. The URL is presigned; no auth header wanted.
    func upload(jpegData: Data, to uploadURL: URL) async throws {
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.upload(for: request, from: jpegData)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw PipelineError.uploadFailed
        }
    }

    /// Run analyze-palm. Maps the documented status codes onto typed errors.
    func analyzePalm(objectKey: String) async throws -> ReadingContent {
        do {
            struct Payload: Encodable { let objectKey: String }
            struct Response: Decodable { let reading: ReadingContent }
            let response: Response = try await client.functions.invoke(
                "analyze-palm",
                options: FunctionInvokeOptions(body: Payload(objectKey: objectKey))
            )
            return response.reading
        } catch let error as FunctionsError {
            throw Self.mapFunctionError(error)
        }
    }

    private static func mapFunctionError(_ error: FunctionsError) -> Error {
        guard case let .httpError(code, data) = error else { return error }
        struct ErrorBody: Decodable {
            let code: String?
            let reason: String?
        }
        let body = try? JSONDecoder().decode(ErrorBody.self, from: data)
        switch code {
        case 402:
            return PipelineError.paywallRequired
        case 422:
            let reason = body?.reason.flatMap(RejectionReason.init(rawValue:)) ?? .flagged
            return PipelineError.rejected(reason)
        case 429:
            return PipelineError.rateLimited
        default:
            return PipelineError.serverError
        }
    }

    // MARK: - Subscription mirroring

    /// POST the signed transaction JWS to verify-subscription (§7.8).
    func verifySubscription(jws: String) async throws {
        struct Payload: Encodable { let jws: String }
        _ = try await client.functions.invoke(
            "verify-subscription",
            options: FunctionInvokeOptions(body: Payload(jws: jws))
        ) as VerifyResponse
    }

    struct VerifyResponse: Decodable {
        let status: String
    }

    // MARK: - Readings

    private struct ReadingRow: Decodable {
        let id: UUID
        let createdAt: Date
        let tier: Reading.Tier
        let content: ReadingContent

        enum CodingKeys: String, CodingKey {
            case id, tier, content
            case createdAt = "created_at"
        }
    }

    /// Fetch the caller's readings, newest first. RLS scopes rows to the user.
    func fetchReadings() async throws -> [Reading] {
        let rows: [ReadingRow] = try await client
            .from("readings")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.map { Reading(id: $0.id, createdAt: $0.createdAt, tier: $0.tier, content: $0.content) }
    }

    /// Delete the account and all rows (cascade), then sign out locally.
    func deleteAccount() async throws {
        _ = try await client.functions.invoke("delete-account") as VerifyResponse
        try await client.auth.signOut()
    }
}

enum PipelineError: Error, Equatable {
    case uploadFailed
    case paywallRequired
    case rejected(RejectionReason)
    case rateLimited
    case serverError
    case timeout
}
