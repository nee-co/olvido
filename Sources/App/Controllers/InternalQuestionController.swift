import Vapor
import HTTP

#if os(Linux)
    import SwiftGlibc
#else
    import Foundation
#endif

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
                                            "message": question.decryptMessage(droplet: drop)
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

    private func arc4random_uniform(_ max: UInt32) -> UInt32 {
        #if os(Linux)
            return UInt32(SwiftGlibc.rand() % Int32(max))
        #else
            return Foundation.arc4random_uniform(max)
        #endif
    }
}