import Vapor
import Fluent

final class Question: Model {
    var id: Node?
    var userId: Int
    var message: String
    var answer: String

    init(userId: Int, message: String, answer: String) throws {
        self.userId  = userId
        self.message = message
        self.answer  = answer
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