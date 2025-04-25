import Foundation

class OpenAIService {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions" // Updated endpoint

    init() {
        // Try loading SecretsLocal.plist first for your actual API key.
        if let localPath = Bundle.main.path(forResource: "SecretsLocal", ofType: "plist"),
           let localDict = NSDictionary(contentsOfFile: localPath),
           let key = localDict["API_KEY"] as? String {
            self.apiKey = key
        }
        // Fallback to public Secrets.plist if it contains a valid key.
        else if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
                let dict = NSDictionary(contentsOfFile: path),
                let key = dict["API_KEY"] as? String, key != "YOUR_API_KEY_HERE" {
            self.apiKey = key
        } else {
            fatalError("API Key not found")
        }
    }

    func fetchAIResponse(prompt: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: endpoint) else {
            print("❌ Debug: Invalid URL")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String: Any] = [
            "model": "gpt-3.5-turbo", // Chat model
            "messages": [
                ["role": "system", "content": "You are a helpful assistant."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 150,
            "temperature": 0.7
        ]

        print("🔍 Debug: OpenAI request parameters: \(parameters)") // Debugging log

        if let body = try? JSONSerialization.data(withJSONObject: parameters) {
            request.httpBody = body
            if let bodyString = String(data: body, encoding: .utf8) {
                print("🔍 Debug: Request body: \(bodyString)") // Debugging log
            }
        } else {
            print("❌ Debug: Failed to serialize request body")
            completion(nil)
            return
        }

        print("🔍 Debug: Request headers: \(request.allHTTPHeaderFields ?? [:])") // Debugging log

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Debug: Network error: \(error.localizedDescription)") // Debugging log
                completion(nil)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 Debug: HTTP status code: \(httpResponse.statusCode)") // Debugging log
                if !(200...299).contains(httpResponse.statusCode) {
                    print("❌ Debug: HTTP error response: \(httpResponse)")
                }
            }

            guard let data = data else {
                print("❌ Debug: No data received") // Debugging log
                completion(nil)
                return
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 Debug: OpenAI raw response: \(jsonString)") // Debugging log
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                print("✅ Debug: Parsed OpenAI response: \(content.trimmingCharacters(in: .whitespacesAndNewlines))") // Debugging log
                completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
            } else {
                print("❌ Debug: Failed to parse OpenAI response") // Debugging log
                completion(nil)
            }
        }.resume()
    }
}
