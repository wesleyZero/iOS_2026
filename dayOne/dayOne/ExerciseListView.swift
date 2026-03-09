//
//  ExerciseListView.swift
//  dayOne
//
//  Created by Wesley James on 3/9/26.
//

import Foundation
import SwiftUI


struct ExerciseListView: View {
    let day: WorkoutDay


    var body: some View {
        List(day.exercises, id: \.name) { exercise in
            Text(exercise.name)
        }
        .navigationTitle(day.name)
    }
}
