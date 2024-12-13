import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case serverError(String)
}

struct RuleSetResponse: Codable {
    let success: Bool
    let data: [RuleSet]
}

class NetworkService {
    static let shared = NetworkService()
    private init() {}
    
    private func buildURL(baseURL: String, path: String) -> URL? {
        let trimmedURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        return URL(string: trimmedURL + path)
    }
    
    func fetchRuleSets(from endpoint: Endpoint) async throws -> [RuleSet] {
        guard let url = buildURL(baseURL: endpoint.url, path: "/rulesets") else {
            print("❌ Invalid URL: \(endpoint.url)")
            throw NetworkError.invalidURL
        }
        
        print("📡 Fetching from URL: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            print("📥 Response received:")
            print("- Status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Received data: \(responseString)")
                
                // 检查响应是否是纯文本错误消息
                if (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Type")?.contains("text/plain") ?? false {
                    throw NetworkError.serverError("Server returned: \(responseString)")
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NetworkError.serverError("Server returned \(httpResponse.statusCode): \(errorMessage)")
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateStr = try container.decode(String.self)
                    print("🕒 Parsing date: \(dateStr)")
                    if let date = DateFormatter.iso8601Full.date(from: dateStr) {
                        return date
                    }
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Cannot decode date string \(dateStr)"
                    )
                }
                let result = try decoder.decode(RuleSetResponse.self, from: data)
                print("✅ Successfully decoded response with \(result.data.count) rulesets")
                return result.data
            } catch {
                print("❌ Decoding error: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Failed to decode: \(responseString)")
                }
                throw NetworkError.decodingError
            }
        } catch {
            print("❌ Network error: \(error)")
            throw error
        }
    }
    
    func fetchRuleSetRecords(endpoint: Endpoint, ruleSetId: String) async throws -> [PortalRecord] {
        guard let url = buildURL(baseURL: endpoint.url, path: "/ruleset/\(ruleSetId)") else {
            throw NetworkError.invalidURL
        }
        
        print("📡 Fetching records from URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Received data: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NetworkError.serverError("Server returned \(httpResponse.statusCode): \(errorMessage)")
        }
        
        let decoder = JSONDecoder()
        // 使用 ISO8601DateFormatter 来处理带毫秒和 Z 后缀的时间戳
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            // 首先尝试解析完整的 ISO8601 格式
            if let date = formatter.date(from: dateStr) {
                return date
            }
            
            // 如果失败，尝试使用简单格式
            if let date = DateFormatter.iso8601Full.date(from: dateStr) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(dateStr)"
            )
        }
        
        let result = try decoder.decode(PortalRecordResponse.self, from: data)
        print("✅ Successfully decoded \(result.data.count) records")
        return result.data
    }
}

extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
} 