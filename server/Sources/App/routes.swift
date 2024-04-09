import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: VotesController(redis: app.redis))

    app.get("ping") { _ in
        "pong"
    }
}
