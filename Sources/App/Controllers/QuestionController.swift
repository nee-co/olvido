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
                                            "message": question.decryptMessage(droplet: drop)
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
            "message": question.decryptMessage(droplet: drop)
        ])

        return try Response(status: .created, json: json)
    }

    func update(request: Request, item question: Question) throws -> ResponseRepresentable {
        if (try question.userId != request.userId()) { return try Response(status: .forbidden, json: JSON(node: [:])) }

        let message: Optional<String> = request.data["message"]?.string
        let answer: Optional<String>  = request.data["answer"]?.string
        var question = try Question(node: question.makeNode())
        try question.setParameters(droplet: drop, message: message, answer: answer)
        try question.save()

        return try Response(status: .noContent, json: JSON(node: [:]))
    }

    func delete(request: Request, item question: Question) throws -> ResponseRepresentable {
        if (try question.userId != request.userId()) { return try Response(status: .forbidden, json: JSON(node: [:])) }
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

        return try Question(droplet: drop, userId: userId, message: message, answer: answer)
    }
}