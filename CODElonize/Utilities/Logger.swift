
import os

enum AppLogger {
    private static let subsystem = "com.arthaz.CODElonize"

    static let ar = Logger(subsystem: subsystem, category: "AR")

    static let networking = Logger(subsystem: subsystem, category: "Networking")

    static let gameplay = Logger(subsystem: subsystem, category: "Gameplay")

    static let quiz = Logger(subsystem: subsystem, category: "Quiz")

    static let ui = Logger(subsystem: subsystem, category: "UI")
}
