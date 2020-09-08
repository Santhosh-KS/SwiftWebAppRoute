import Kitura
import HeliumLogger
import LoggerAPI
import KituraContracts

HeliumLogger.use(.info)
//
let router = Router()

router.get("/hello", handler: {
    request, response, next in
    defer { next() }
    response.send("Hello")
},{
    request, response, next in
    defer { next() }
    response.send(", world")
})

router.route("/test")
.get() {
    request, response, next in
    defer { next() }
    response.send("you used GET method")
}
.post() {
    request, response, next in
    defer { next() }
    response.send("you used POST method")
}

router.get("/games/:name") {
    request, response, next in
    defer { next() }
    guard let name = request.parameters["name"] else { return }
    response.send("Load the \(name) game")
}

// http://localhost:8090/platforms?name=iOS
router.get("/platforms") {
    request, response, next in
    guard let name = request.queryParameters["name"] else {
    try response.status(.badRequest).end()
    return
    }
    response.send("Loading the \(name) platform")
    next()
}

// curl -vX POST -H "content-type:application/json" localhost:8090/messages/create -d '{"title": "Swift: great language orgreatest language?"}'
router.post("/messages/create", middleware: BodyParser())
router.post("/messages/create") {
    request, response, next in
    guard let values = request.body else {
        try response.status(.badRequest).end()
        return
    }
    guard case .json(let body) = values else {
        try response.status(.badRequest).end()
        return
    }
    if let title = body["title"] as? String {
        response.send("Adding new message with the title \(title)")
    } else {
    response.send("You need to provide a title.")
    }
    next()
}

struct Singer: Codable {
    var name: String
    var age: Int
}

var singers = [
    Singer(name: "Taylor Swift", age: 27),
    Singer(name: "Justin Bieber", age: 23),
    Singer(name: "Ed Sheeran", age: 26)
]

router.get("/singers/all") {
    (completion: ([Singer]?, RequestError?) -> Void) in
    completion(singers, nil)
}

// curl -vX GET localhost:8090/singers/2
router.get("/singers") {
    (id: Int, completion: (Singer?, RequestError?) -> Void) in
    completion(singers[id], nil)
}

// curl -vX GET localhost:8090/singers/swift
router.get("/singers") {
    (name: String, completion: (Singer?, RequestError?) -> Void) in
    let singer = singers.first { $0.name.lowercased().contains(name.lowercased()) }
    completion(singer, nil)
}

// if the user sends a request with singer's name not availalbe then above code returns 500 error.
// To get it corected we have the if clause in this route
// curl -vX GET localhost:8090/singers/marlyn
router.get("/singers") {
    (name: String, completion: (Singer?, RequestError?) -> Void) in
    let singer = singers.first { $0.name.lowercased().contains(name.lowercased()) }
    if let singer = singer {
        completion(singer, nil)
    } else {
        completion(nil, RequestError.notFound)
    }
}

router.post("/singers/add") {
    (singer: Singer, completion: (Singer?, RequestError?) -> Void) in
    singers.append(singer)
    print(singers.count)
    completion(singer, nil)
}

// curl -vX GET localhost:8090/search/2020/covid
router.get("/search/([0-9]+)/([A-Za-z]+)") {
    request, response, next in
    defer { next() }
    guard let year = request.parameters["0"] else { return }
    guard let string = request.parameters["1"] else { return }
    response.send("You searched for \(string) in \(year)")
}

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()