# RESTManager

### How to use this package?
- Add the package through Xcode. 
- Create an instance inside the viewController file right before the viewDidLoad() method. 
- This package can be used to: 
    - fetch data from the API with and without response headers
    - pass URL query parameters in the process of making get request.
    - Creation of new Data into the REST API with the configuration of HTTP Headers and the body parameters. 
    - Fetching of single data from the api and store it into a Cache/FileManager directory.

- Here is a detailed example of what you can do with this pacakage:
  - Fetch data without response headers
  ``` 
    func getUsersList() {
        guard let url = URL(string: "https://reqres.in/api/users") else {return }
    
        rest.makeRequest(toURL: url, withHttpMethod: .get) { result in
            if let data = result.data {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                guard let userData = try? decoder.decode(UserData.self, from: data) else {return }
                print(userData.description)
            }
        }
    }
    ```
  - Fetch response headers from the request.
  ```
     func getUsersListwithHeaders() {
        guard let url = URL(string: "https://reqres.in/api/users") else { return }
    
        rest.makeRequest(toURL: url, withHttpMethod: .get) { result in
            if let data = result.data { }
            print("Response HTTP Headers")
        
            if let response = result.response {
                for (key, value) in response.headers.allValues() {
                    print(key, value)
                }
            }
        }
    }
    ```
  - Pass URL query params with the request. 
  ```
    func getUsers() {
        guard let url = URL(string: "https://reqres.in/api/users") else { return }
    
        //this will create the url like https://reres.in/api/users?page=2
        rest.urlQueryParameters.add(value: "2", forKey: "page")
    
        rest.makeRequest(toURL: url, withHttpMethod: .get) { result in
            //
        }
    }
    ```
  - Creation of new Data into the REST API with the configuration of HTTP Headers and the body parameters.
  ```
    func createData() {
        guard let url = URL(string: "https://reqres.in/api/users") else {return  }
    
        rest.requestHTTPHeaders.add(value: "application/json", forKey: "Content-Type")
        rest.httpBodyParams.add(value: "Shilpee", forKey: "name")
        rest.httpBodyParams.add(value: "SDE-1", forKey: "job")
    
        rest.makeRequest(toURL: url, withHttpMethod: .post) { result in
            guard let response = result.response else { return }
            if response.httpStatusCode == 201 {
                if response.httpStatusCode == 201 {
                    guard let data = result.data else {return }
                    let decoder = JSONDecoder()
                    guard let newData = try? decoder.decode(JobUser.self, from: data) else {return}
                    print(newData.description)
                }
            }
        }
    }
    ```
  - Fetching of single data from the api and store it into a Cache/FileManager directory. 
  ```
      func getSingleData() {
          guard let url = URL(string: "https://reqres.in/api/users/1")else {return}
    
          rest.makeRequest(toURL: url, withHttpMethod: .get) { result in
              if let data = result.data {
            
                  let decoder = JSONDecoder()
                  decoder.keyDecodingStrategy = .convertFromSnakeCase
                  guard let singleData = try? decoder.decode(SingleData.self, from: data),
                      let user = singleData.data,
                      let avatar = user.avatar,
                      let url = URL(string: avatar)else { return }
            
                  rest.getData(fromURL: url) { avatarData in
                      guard let avatarData = avatarData else { return }
                      let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                      let saveURL = cachesDirectory.appendingPathComponent("avatar.jpg")
                      try? avatarData.write(to: saveURL)
                      print("Saved Avatar url \(saveURL) ")
                  }
              }
          }
    }
  ```
