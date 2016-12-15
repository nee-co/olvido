import Vapor
import HTTP
import Cocoa

final class InternalQuestionController: ResourceRepresentable {
    let drop: Droplet

    init(droplet: Droplet) {
        drop = droplet
    }

    func randomQuestion(request: Request) throws -> ResponseRepresentable {
        guard let userId = request.data["user_id"]?.string else { throw Abort.badRequest }
        let questions = try Question.query()
                                    .filter("user_id", userId)
                                    .all()
                                    .map { (question: Question) -> JSON in
                                        try JSON(node: [
                                            "id": question.id!.int,
                                            "message": drop.cipher.decrypt(question.message)
                                        ])
                                    }
        let randomNum = Int(arc4random_uniform(UInt32(questions.count)))

        return try Response(status: .ok, json: questions[randomNum])
    }

    func makeResource() -> Resource<String> {
        return Resource(
            index: randomQuestion
        )
    }
}