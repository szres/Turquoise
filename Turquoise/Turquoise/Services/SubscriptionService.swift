import Foundation

class SubscriptionService {
    static let shared = SubscriptionService()
    private let baseURL = "https://turquoise.szres.org"
    private init() {}
    
    private func checkDeviceToken() throws -> String {
        guard let token = UserDefaults.standard.string(forKey: "APNSDeviceToken") else {
            print("❌ Device token not found in UserDefaults")
            print("🔍 Available UserDefaults keys:")
            for key in UserDefaults.standard.dictionaryRepresentation().keys {
                print("- \(key)")
            }
            throw NetworkError.serverError("Device token not found")
        }
        return token
    }
    
    func subscribe(ruleSetId: String) async throws {
        let token = try checkDeviceToken()
        print("📱 Device Token: \(token)")
        
        guard let url = URL(string: "\(baseURL)/subscribe") else {
            throw NetworkError.invalidURL
        }
        
        let body = [
            "topic": ruleSetId,
            "method": "APNS",
            "token": token
        ]
        
        print("📤 Sending subscription request:")
        print("URL: \(url)")
        print("Body: \(body)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("📥 Response received:")
        print("Status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response body: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NetworkError.serverError("Server returned \(httpResponse.statusCode): \(errorMessage)")
        }
    }
    
    func unsubscribe(ruleSetId: String) async throws {
        let token = try checkDeviceToken()
        print("📱 Device Token: \(token)")
        
        guard let url = URL(string: "\(baseURL)/unsubscribe") else {
            throw NetworkError.invalidURL
        }
        
        let body = [
            "topic": ruleSetId,
            "method": "APNS",
            "token": token
        ]
        
        print("📤 Sending unsubscription request:")
        print("URL: \(url)")
        print("Body: \(body)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("📥 Response received:")
        print("Status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response body: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NetworkError.serverError("Server returned \(httpResponse.statusCode): \(errorMessage)")
        }
    }
} 