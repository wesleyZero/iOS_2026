import SwiftUI

struct ContentView: View {
    let days = [
        WorkoutDay(name: "A", exercises: [
            Exercise(name: "Dumbbell Press", sets: [
                LoggedSet(weight: 55, reps: 6),
                LoggedSet(weight: 50, reps: 7),
                LoggedSet(weight: 50, reps: 2),
                LoggedSet(weight: 40, reps: 7)
            ]),
            Exercise(name: "Lateral Raises", sets: [
                LoggedSet(weight: 35, reps: 16),
                LoggedSet(weight: 35, reps: 10),
                LoggedSet(weight: 35, reps: 7),
                LoggedSet(weight: 35, reps: 7),
                LoggedSet(weight: 35, reps: 5)
            ]),
            Exercise(name: "Cable Flys", sets: [
                LoggedSet(weight: 27, reps: 4),
                LoggedSet(weight: 23, reps: 6)
            ]),
            Exercise(name: "Shrugs", sets: [
                LoggedSet(weight: 75, reps: 10),
                LoggedSet(weight: 60, reps: 10)
            ]),
            Exercise(name: "Tricep Pull Down Rope", sets: [
                LoggedSet(weight: 30, reps: 9),
                LoggedSet(weight: 30, reps: 7),
                LoggedSet(weight: 30, reps: 4),
                LoggedSet(weight: 30, reps: 4),
                LoggedSet(weight: 30, reps: 3)
            ])
        ]),
        WorkoutDay(name: "B", exercises: [
            Exercise(name: "Lat Pulldown", sets: [
                LoggedSet(weight: 140, reps: 7),
                LoggedSet(weight: 140, reps: 5),
                LoggedSet(weight: 140, reps: 4),
                LoggedSet(weight: 140, reps: 4)
            ]),
            Exercise(name: "Incline Dumbbell Row", sets: [
                LoggedSet(weight: 135, reps: 9),
                LoggedSet(weight: 135, reps: 8),
                LoggedSet(weight: 135, reps: 7),
                LoggedSet(weight: 135, reps: 5),
                LoggedSet(weight: 135, reps: 5)
            ]),
            Exercise(name: "Low Cable Row", sets: [
                LoggedSet(weight: 160, reps: 4),
                LoggedSet(weight: 145, reps: 7),
                LoggedSet(weight: 145, reps: 5),
                LoggedSet(weight: 145, reps: 5)
            ]),
            Exercise(name: "Barbell Curls", sets: [
                LoggedSet(weight: 50, reps: 9),
                LoggedSet(weight: 50, reps: 8),
                LoggedSet(weight: 50, reps: 4),
                LoggedSet(weight: 50, reps: 3)
            ]),
            Exercise(name: "Hyperextensions", sets: [
                LoggedSet(weight: 45, reps: 8),
                LoggedSet(weight: 45, reps: 7),
                LoggedSet(weight: 45, reps: 7),
                LoggedSet(weight: 45, reps: 7)
            ])
        ]),
        WorkoutDay(name: "C", exercises: [
            Exercise(name: "Squat", sets: [
                LoggedSet(weight: 180, reps: 5)
            ])
        ])
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
