import SwiftUI

struct ContentView: View {
    let days = [
        WorkoutDay(name: "A", exercises: []),
        WorkoutDay(name: "B", exercises: []),
        WorkoutDay(name: "C", exercises: [])
    ]

    var body: some View {
        NavigationStack{
            List(days) { day in
                NavigationLink("Day \(day.name)") {
//                    Text("Exercises for the day \(day.name)")
                    ExerciseListView(day: day)
                    
                }
            }
            .navigationTitle("Workout")
        }
    }
}

#Preview {
    ContentView()
}
