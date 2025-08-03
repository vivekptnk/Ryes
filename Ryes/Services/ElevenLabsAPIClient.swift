import Foundation
import Network

/// Core HTTP client for ElevenLabs API integration
/// Handles authentication, request construction, and response processing
class ElevenLabsAPIClient {
    
    // MARK: - Properties
    
    private let baseURL = "https://api.elevenlabs.io/v1"
    private let keychainManager = KeychainManager.shared
    
    // MARK: - Initialization
    
    init() {
        // Simple init with no URLSession setup
    }
    
    // MARK: - Text-to-Speech API
    
    /// Converts text to speech using ElevenLabs API
    /// - Parameters:
    ///   - text: Text to convert to speech
    ///   - voiceId: ID of the voice to use
    ///   - voiceSettings: Voice configuration settings
    ///   - completion: Completion handler with audio data or error
    func textToSpeech(
        text: String,
        voiceId: String,
        voiceSettings: VoiceSettings = .alarmOptimized,
        completion: @escaping (Result<Data, ElevenLabsError>) -> Void
    ) {
        // Validate API key
        guard let apiKey = keychainManager.retrieveElevenLabsAPIKey() else {
            completion(.failure(.apiKeyNotConfigured))
            return
        }
        
        // Construct request
        let request = TextToSpeechRequest(
            text: text,
            modelId: TextToSpeechRequest.ModelID.flash,
            voiceSettings: voiceSettings
        )
        
        // Validate request
        do {
            try request.validate()
            try voiceSettings.validate()
        } catch let error as ElevenLabsError {
            completion(.failure(error))
            return
        } catch {
            completion(.failure(.badRequest(message: error.localizedDescription)))
            return
        }
        
        // Create URL request
        guard let url = URL(string: "\(baseURL)/text-to-speech/\(voiceId)") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        // Encode request body
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(.badRequest(message: "Failed to encode request")))
            return
        }
        
        // Execute request using basic URLSession
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                // Handle network errors
                if let error = error {
                    if let urlError = error as? URLError {
                        completion(.failure(ElevenLabsError.from(urlError)))
                    } else {
                        completion(.failure(.unknownError(underlying: error)))
                    }
                    return
                }
                
                // Handle HTTP response
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                // Check for success status codes
                switch httpResponse.statusCode {
                case 200...299:
                    guard let data = data else {
                        completion(.failure(.noData))
                        return
                    }
                    // Simple audio validation
                    if data.count > 1024 {
                        completion(.success(data))
                    } else {
                        completion(.failure(.invalidAudioFormat))
                    }
                    
                default:
                    let error = ElevenLabsError.from(
                        statusCode: httpResponse.statusCode,
                        data: data,
                        response: httpResponse
                    )
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
    
    // MARK: - Voice Management API
    
    /// Retrieves available voices from ElevenLabs
    /// - Parameter completion: Completion handler with voices array or error
    func getVoices(completion: @escaping (Result<[Voice], ElevenLabsError>) -> Void) {
        guard let apiKey = keychainManager.retrieveElevenLabsAPIKey() else {
            completion(.failure(.apiKeyNotConfigured))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/voices") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.networkUnavailable))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    guard let data = data else {
                        completion(.failure(.noData))
                        return
                    }
                    do {
                        let response = try JSONDecoder().decode(VoicesResponse.self, from: data)
                        completion(.success(response.voices))
                    } catch {
                        completion(.failure(.invalidResponse))
                    }
                default:
                    let error = ElevenLabsError.from(
                        statusCode: httpResponse.statusCode,
                        data: data,
                        response: httpResponse
                    )
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
    
    /// Adds a new voice through voice cloning
    /// - Parameters:
    ///   - request: Voice creation request
    ///   - audioFiles: Array of audio file data for voice training
    ///   - completion: Completion handler with voice creation response or error
    func addVoice(
        request: AddVoiceRequest,
        audioFiles: [Data],
        completion: @escaping (Result<AddVoiceResponse, ElevenLabsError>) -> Void
    ) {
        guard let apiKey = keychainManager.retrieveElevenLabsAPIKey() else {
            completion(.failure(.apiKeyNotConfigured))
            return
        }
        
        guard !audioFiles.isEmpty else {
            completion(.failure(.badRequest(message: "At least one audio file is required")))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/voices/add") else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        // Build multipart body
        var body = Data()
        
        // Add name field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(request.name)\r\n".data(using: .utf8)!)
        
        // Add description if provided
        if let description = request.description {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"description\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(description)\r\n".data(using: .utf8)!)
        }
        
        // Add audio files
        for (index, audioData) in audioFiles.enumerated() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"files\"; filename=\"voice_sample_\(index).wav\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.networkUnavailable))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    guard let data = data else {
                        completion(.failure(.noData))
                        return
                    }
                    do {
                        let response = try JSONDecoder().decode(AddVoiceResponse.self, from: data)
                        completion(.success(response))
                    } catch {
                        completion(.failure(.invalidResponse))
                    }
                default:
                    let error = ElevenLabsError.from(
                        statusCode: httpResponse.statusCode,
                        data: data,
                        response: httpResponse
                    )
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
    
    /// Gets user subscription information
    /// - Parameter completion: Completion handler with user info or error
    func getUserInfo(completion: @escaping (Result<UserResponse, ElevenLabsError>) -> Void) {
        guard let apiKey = keychainManager.retrieveElevenLabsAPIKey() else {
            completion(.failure(.apiKeyNotConfigured))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/user") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.networkUnavailable))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    guard let data = data else {
                        completion(.failure(.noData))
                        return
                    }
                    do {
                        let response = try JSONDecoder().decode(UserResponse.self, from: data)
                        completion(.success(response))
                    } catch {
                        completion(.failure(.invalidResponse))
                    }
                default:
                    let error = ElevenLabsError.from(
                        statusCode: httpResponse.statusCode,
                        data: data,
                        response: httpResponse
                    )
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
}