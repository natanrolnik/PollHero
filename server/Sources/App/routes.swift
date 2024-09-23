import Vapor

func routes(_ app: Application) throws {
    var enableSocket = true

    if let disableSocket = Environment.get("DISABLE_SOCKETS").flatMap(Bool.init),
       disableSocket {
        enableSocket = false
    }

    let votesController = VotesController(
        enableSocket: enableSocket,
        logger: app.logger,
        redis: app.redis
    )

    try app.register(collection: votesController)

    app.get("ping") { _ in
        "pong"
    }
}
