import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: VotesController(redis: app.redis))
}
