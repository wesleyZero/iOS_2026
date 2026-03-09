import SwiftUI

struct ContentView: View {
    let days = [ WorkoutDay(name: "A", exercises: []) ]

    var body: some View {
        NavigationStack{
//            List(days, id: \.self) { day in
//                NavigationLink("Day \(day)") {
//                    Text("Exercises for the day \(day)")
//                }
//            }
//            .navigationTitle("Workout")
        }
    }
}

#Preview {
    ContentView()
}
