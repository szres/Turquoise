import Foundation

class SubscriptionService {
    static let shared = SubscriptionService()
    private let baseURL = "https://turquoise.szres.org"
    private init() {}
    
    private func checkDeviceToken() throws -> String {
        guard let token = UserDefaults.standard.string(forKey: "APNSDeviceToken") else {
            throw NetworkError.serverError("Device token not found. Please check notification permissions.")
        }
        return token
    }
    
    func fetchSubscribedTopics() async throws -> [String] {
        let token = try checkDeviceToken()
        
        var components = URLComponents(string: "\(baseURL)/subscriptions")
        components?.queryItems = [
            URLQueryItem(name: "method", value: "APNS"),
            URLQueryItem(name: "token", value: token)
        ]
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        print("📡 Fetching subscriptions from URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(TopicsResponse.self, from: data)
        return result.data
    }
    
    func subscribe(ruleSetId: String) async throws {
        let token = try checkDeviceToken()
        
        guard let url = URL(string: "\(baseURL)/subscribe") else {
            throw NetworkError.invalidURL
        }
        
        let body = [
            "topic": ruleSetId,
            "method": "APNS",
            "token": token
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NetworkError.serverError("Failed to subscribe: \(errorMessage)")
        }
    }
    
    func unsubscribe(ruleSetId: String) async throws {
        let token = try checkDeviceToken()
        
        guard let url = URL(string: "\(baseURL)/unsubscribe") else {
            throw NetworkError.invalidURL
        }
        
        let body = [
            "topic": ruleSetId,
            "method": "APNS",
            "token": token
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NetworkError.serverError("Failed to unsubscribe: \(errorMessage)")
        }
    }
}

struct TopicsResponse: Codable {
    let success: Bool
    let data: [String]
} 