import Vapor
import VaporMySQL

let drop = Droplet(
    preparations: [Question.self],
    providers: [VaporMySQL.Provider.self]
)

drop.resource("posts", PostController())

drop.run()
