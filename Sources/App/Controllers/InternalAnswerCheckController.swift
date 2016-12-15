import Vapor
import HTTP

final class InternalAnswerCheckController: ResourceRepresentable {
    let drop: Droplet

    init(droplet: Droplet) {
        drop = droplet
    }

    func check(request: Request) throws -> ResponseRepresentable {
        guard let questionId = request.parameters["id"]?.int,
              let answer = request.data["answer"]?.string else { throw Abort.custom(status: .unprocessableEntity, message: "")}
        guard let question = try Question.query().filter("id", questionId).all().first else { throw Abort.notFound }

        if (try question.answer == drop.hash.make(answer)) {
            return try Response(status: .ok, json: JSON(node: ["id": question.userId]))
        } else {
            return try Response(status: .unprocessableEntity, json: JSON(node: [:]))
        }
    }

    func makeResource() -> Resource<String> {
        return Resource(
                store: check
        )
    }
}