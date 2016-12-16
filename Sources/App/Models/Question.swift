import Vapor
import Fluent

final class Question: Model {
    var id: Node?
    var userId: Int
    var message: String
    var answer: String

    init(droplet: Droplet, userId: Int, message: String, answer: String) throws {
        self.userId  = userId
        try self.message = droplet.cipher.encrypt(message)
        try self.answer  = droplet.hash.make(answer)
    }

    init(node: Node, in context: Context) throws {
        id      = try node.extract("id")
        userId  = try node.extract("user_id")
        message = try node.extract("message")
        answer  = try node.extract("answer")
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id"     : id,
            "user_id": userId,
            "message": message,
            "answer" : answer
        ])
    }

    func setParameters(droplet: Droplet, message: Optional<String>, answer: Optional<String>) throws {
        switch (message, answer) {
            case (let .some(message), let .some(answer)) :
                try self.message = droplet.cipher.encrypt(message)
                try self.answer  = droplet.hash.make(answer)
            case (let .some(message), .none) :
                try self.message = droplet.cipher.encrypt(message)
            case (.none, let .some(answer)) :
                try self.answer  = droplet.hash.make(answer)
            default :
                return
        }
    }

    func decryptMessage(droplet: Droplet) throws -> String {
        return try droplet.cipher.decrypt(message)
    }

    static func prepare(_ database: Database) throws {
        try database.create("questions") { questions in
            questions.id()
            questions.int("user_id")
            questions.string("message")
            questions.string("answer")
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete("questions")
    }
}