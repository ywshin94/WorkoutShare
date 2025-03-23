import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var stravaService: StravaService
    
    var body: some View {
        NavigationView {
            if stravaService.accessToken == nil {
                VStack {
                    Button("Login with Strava") {
                        stravaService.startOAuthFlow()
                    }
                    Text("Access Token: \(stravaService.accessToken ?? "nil")")
                        .padding()
                        .foregroundColor(.gray)
                    if let error = stravaService.errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            } else {
                VStack {
                    Text("Access Token: \(stravaService.accessToken ?? "nil")")
                        .padding()
                        .foregroundColor(.gray)
                    WorkoutListView(workouts: stravaService.workouts)
                }
            }
        }
        .onChange(of: stravaService.accessToken) { newValue in
            print("Access Token changed to: \(newValue ?? "nil")")
        }
        .onAppear {
            print("Initial Access Token: \(stravaService.accessToken ?? "nil")")
        }
    }
}
