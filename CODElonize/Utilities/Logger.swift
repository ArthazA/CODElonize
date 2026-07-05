//
//  Logger.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import os

/// Centralized loggers organized by subsystem.
/// Usage: `AppLogger.ar.info("Plane detected")`
enum AppLogger {
    private static let subsystem = "com.arthaz.CODElonize"
    
    /// AR session, plane detection, island placement, pinpoints.
    static let ar = Logger(subsystem: subsystem, category: "AR")
    
    /// Multipeer connectivity, lobby management, message passing.
    static let networking = Logger(subsystem: subsystem, category: "Networking")
    
    /// Match flow, area conquest, scoring, power-ups.
    static let gameplay = Logger(subsystem: subsystem, category: "Gameplay")
    
    /// Question loading, randomization, answer validation.
    static let quiz = Logger(subsystem: subsystem, category: "Quiz")
    
    /// UI navigation, screen transitions, user interactions.
    static let ui = Logger(subsystem: subsystem, category: "UI")
}
