//
//  Untitled.swift
//  dayOne
//
//  Created by Wesley James on 3/6/26.

import Foundation

struct WorkoutDay: Identifiable {
    let id = UUID()
    let name: String
    var exercises: [Exercise]
}

struct Exercise {
    var name: String
    var sets: [LoggedSet]

    var volume: Double {
        var total = 0.0
        for set in sets {
            total += set.weight * Double(set.reps)
        }
        return total
    }

}

struct LoggedSet {
    var weight: Double
    var reps: Int
}

