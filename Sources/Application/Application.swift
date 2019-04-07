import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

public class App {
    let router = Router()
    let cloudEnv = CloudEnv()

    private var memos = [Int: Memo]()
    private var nextID = 0

    public init() throws {
        // Run the metrics initializer
        initializeMetrics(router: router)
    }

    func postInit() throws {
        // Endpoints
        initializeHealthRoutes(app: self)

        router.post("/memos") { (memo: Memo, respondWith: (Memo?, RequestError?) -> Void) in
            let id = self.nextID
            self.nextID += 1

            let new = Memo(id: id, text: memo.text)
            self.memos[id] = new

            respondWith(new, nil)
        }
        router.get("/memos") { (respondWith: ([Memo]?, RequestError?) -> Void) in
            respondWith(self.memos.values.map({ $0 }), nil)
        }
        router.get("/memos") { (id: Int, respondWith: (Memo?, RequestError?) -> Void) in
            if let memo = self.memos[id] {
                respondWith(memo, nil)
            } else {
                respondWith(nil, .notFound)
            }
        }
        router.put("/memos") { (id: Int, memo: Memo, respondWith: (Memo?, RequestError?) -> Void) in
            if self.memos[id] != nil {
                let modified = Memo(id: id, text: memo.text)
                self.memos[id] = modified
                respondWith(modified, nil)
            } else {
                respondWith(nil, .notFound)
            }
        }
        
    }

    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }
}

public struct Memo: Codable {
    public var id: Int?
    public var text: String?
}
