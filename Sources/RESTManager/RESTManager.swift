import Foundation

class RESTManager {
    
    var requestHTTPHeaders = RestEntity()
    var urlQueryParameters = RestEntity()
    var httpBodyParams = RestEntity()
    
    var httpBody: Data?
    
    public init() {
    }
    
    private func addURLQueryParameters(toURl url: URL)-> URL {
        if urlQueryParameters.totalItems() > 0 {
            guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
            
            var queryItems = [URLQueryItem]()
            for (key, value) in urlQueryParameters.allValues() {
                //passing value by converting the value into per cent encoding
//                https://someUrl.com?phrase=hello world is converted to https://someUrl.com?phrase=hello%20world
                
                let item = URLQueryItem(name: key, value: value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))
                
                
                queryItems.append(item)
            }
            urlComponents.queryItems = queryItems
            guard let updatedURL = urlComponents.url else { return url }
            return updatedURL
        }
        return url
    }
    
    private func getHttpBody() -> Data? {
        guard let contentType = requestHTTPHeaders.value(forKey: "Content-type") else { return nil }
        
        if contentType.contains("application/json") {
            return try? JSONSerialization.data(withJSONObject: httpBodyParams.allValues(), options: [.prettyPrinted, .sortedKeys])
        }else if contentType.contains("application/x-www-form-urlencoded"){
            let bodyString = httpBodyParams.allValues().map { "\($0)=\(String(describing: $1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)))" }.joined(separator: "&")
            return bodyString.data(using: .utf8)
        }else {
            return httpBody
        }
    }
    
    private func prepareRequest(withURL url: URL?, httpBody: Data?, httpMethod: HTTPMethod) -> URLRequest? {
        guard let url = url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        
        for (header, value) in requestHTTPHeaders.allValues() {
            request.setValue(value, forHTTPHeaderField: header)
        }
        
        request.httpBody = httpBody
        return request
    }
    
    func makeRequest(toURL url: URL, withHttpMethod httpMethod: HTTPMethod, completion: @escaping (_ result: Results) -> Void ){
        //main thread should remain free to be used by the app
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let targetURL = self?.addURLQueryParameters(toURl: url)
            let httpBody = self?.getHttpBody()
            
            guard let request = self?.prepareRequest(withURL: targetURL, httpBody: httpBody, httpMethod: httpMethod)else {
                completion(Results(withError: CustomError.failedToCreateRequest))
                return
            }
            
            let sessionConfiguration = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfiguration)
            let task = session.dataTask(with: request){ (data, response, error) in
                completion(Results(withData: data,
                                   response: Response(fromURLResponse: response),
                                   error: error))
            }
            task.resume()
        }
    }
    
    func getData(fromURL url: URL, completion: @escaping (_ data: Data?) -> Void){
        //fetch single data from the url
        DispatchQueue.global(qos: .userInitiated).async {
            let sessionConfiguration = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfiguration)
            let task = session.dataTask(with: url) { data, response, error in
                guard let data = data else { completion(nil); return }
                completion(data)
            }
            task.resume()
        }
    }
}

// MARK: - RestManager Custom types

extension RESTManager{
    enum HTTPMethod: String {
        case get
        case post
        case put
        case patch
        case delete
    }
    
    struct RestEntity {
        private var values: [String: String] = [:]
        
        //set value to the key
        mutating func add(value: String, forKey key: String){
            values[key] = value
        }
        
        //return the value from the key
        func value(forKey key: String) -> String? {
            return values[key]
        }
        
        func allValues()-> [String: String] {
            return values
        }
        func totalItems() -> Int{
            return values.count
        }
    }
    
    //response contains status code, response body, http headers optionally
    struct Response {
        var response: URLResponse?
        var httpStatusCode: Int = 0
        var headers = RestEntity()
        
        //accepts urlresponse object
        init(fromURLResponse response : URLResponse?) {
            guard let response = response else { return }
            self.response=response
            self.response = response
            httpStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            
            if let headerFields = (response as? HTTPURLResponse)?.allHeaderFields {
                for (key, value ) in headerFields{
                    headers.add(value: "\(value)", forKey: "\(key)")
                }
            }
        }
        
    }
    
    struct Results {
        var data: Data?
        var response: Response?
        var error: Error?
        
        init(withData data: Data? = nil, response: Response? = nil, error: Error? = nil) {
            self.data = data
            self.response = response
            self.error = error
        }
        
        init(withError error: Error){
            self.error=error
        }
    }
    
    enum CustomError: Error {
        case failedToCreateRequest
    }
}
extension RESTManager.CustomError: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .failedToCreateRequest: return NSLocalizedString("Unable to create the URLRequest object", comment: "")
        }
    }
}
