//
//  StudyTimerAttributes.swift
//  Cosmos
//
//  Created by James Williams on 4/6/25.
//
import Foundation

#if os(iOS)
import ActivityKit

struct StudyTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timeRemaining: Int
        var endDate: Date
    }
    var topic: String
}
#else
// macOS fallback stub — Live Activity not available.
struct StudyTimerAttributes {
    var topic: String
    struct ContentState: Codable, Hashable {
        var timeRemaining: Int
        var endDate: Date
    }
}
#endif
