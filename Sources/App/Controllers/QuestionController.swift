import Vapor
import HTTP

final class QuestionController: ResourceRepresentable {
    let drop: Droplet

    init(droplet: Droplet) {
        drop = droplet
    }

    func index(request: Request) throws -> ResponseRepresentable {
        let userId = try request.userId()
        let questions = try Question.query()
                                    .filter("user_id", userId)
                                    .all()
                                    .map { (question: Question) -> JSON in
                                        try JSON(node: [
                                            "id": question.id!.int,
                                            "message": drop.cipher.decrypt(question.message)
                                        ])
                                    }
                                    .makeNode()
                                    .converted(to: JSON.self)

        return try Response(status: .ok, json: JSON(["questions": questions]))
    }

    func create(request: Request) throws -> ResponseRepresentable {
        var question = try request.question()
        try question.save()
        let json = try JSON(node: [
            "id": question.id!.int,
            "message": drop.cipher.decrypt(question.message)
        ])

        return try Response(status: .created, json: json)
    }

    func update(request: Request, item question: Question) throws -> ResponseRepresentable {
        let userId = try request.userId()
        guard let message = request.data["message"]?.string,
              let answer  = request.data["answer"]?.string else { throw Abort.custom(status: .unprocessableEntity, message: "")}

        if (question.userId != userId) { return try Response(status: .forbidden, json: JSON(node: [:])) }

        var question = try Question(node: question.makeNode())
        try question.message = drop.cipher.encrypt(message)
        try question.answer  = drop.hash.make(answer)
        try question.save()

        return try Response(status: .noContent, json: JSON(node: [:]))
    }

    func delete(request: Request, item question: Question) throws -> ResponseRepresentable {
        let userId = try request.userId()

        if (question.userId != userId) { return try Response(status: .forbidden, json: JSON(node: [:])) }

        try question.delete()

        return try Response(status: .noContent, json: JSON(node: [:]))
    }

    func makeResource() -> Resource<Question> {
        return Resource(
            index: index,
            store: create,
            modify: update,
            destroy: delete
        )
    }
}

extension Request {
    func userId() throws -> Int {
        guard let userId = headers["x-consumer-custom-id"]?.int else { throw Abort.custom(status: .unauthorized, message: "")}

        return userId
    }

    func question() throws -> Question {
        guard let userId  = headers["x-consumer-custom-id"]?.int,
              let message = data["message"]?.string,
              let answer  = data["answer"]?.string else { throw Abort.custom(status: .unprocessableEntity, message: "") }

        return try Question(userId: userId, message: drop.cipher.encrypt(message), answer: drop.hash.make(answer))
    }
}