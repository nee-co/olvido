import Vapor
import VaporMySQL

let drop = Droplet(
    preparations: [Question.self],
    providers: [VaporMySQL.Provider.self]
)

drop.resource("/questions", QuestionController(droplet: drop))
drop.resource("/internal/questions", InternalQuestionController(droplet: drop))
drop.resource("/internal/questions/:id", InternalAnswerCheckController(droplet: drop))

drop.run()
