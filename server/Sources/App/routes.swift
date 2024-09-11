import Vapor

func routes(_ app: Application) throws {
    let votesController = VotesController(
        logger: app.logger,
        redis: app.redis
    )

    try app.register(collection: votesController)

    app.get("ping") { _ in
        "pong"
    }
}
