import Vapor
import VaporMySQL

let drop = Droplet(
    providers: [VaporMySQL.Provider.self]
)

drop.resource("posts", PostController())

drop.run()
