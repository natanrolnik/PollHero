import Redis
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    // cors middleware should come before default error middleware using `at: .beginning`
    app.middleware.use(cors, at: .beginning)

    if let redisURL = Environment.get("REDIS_URL") ?? Environment.get("STACKHERO_REDIS_URL_TLS") {
        app.redis.configuration = try RedisConfiguration(
            url: redisURL,
            pool: .init(connectionRetryTimeout: .seconds(5))
        )
    } else {
        app.redis.configuration = try RedisConfiguration(hostname: "localhost")
    }

    if let port = Environment.get("PORT").flatMap(Int.init(_:)) {
        app.http.server.configuration.port = port
    }

    // register routes
    try routes(app)
}
