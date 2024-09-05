import SwiftUI

struct WelcomeScreen: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemGreen), Color(.systemBackground)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Image(systemName: "car")
                        .imageScale(.large)
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    Text("Welcome to Ghost")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    Text("Track your journeys and performance with ease")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 40)
                    
                    NavigationLink(destination: SignUpScreen()) {
                        Text("Sign Up")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.6))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    NavigationLink(destination: LoginScreen()) {
                        Text("Login")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                }
                .padding()
            }
        }
    }
}

struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreen()
            .environmentObject(AuthManager())
    }
}
