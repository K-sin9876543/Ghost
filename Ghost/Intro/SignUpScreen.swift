import SwiftUI
import Firebase
import FirebaseAuth

struct SignUpScreen: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @State private var isSignedUp: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Sign Up")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                Text("Create a new account to get started")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.bottom, 30)
                
                TextField("Username", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button(action: {
                    signUp()
                }) {
                    Text("Sign Up")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .disabled(isLoading)
                
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.white)
                    
                    NavigationLink(destination: LoginScreen()) {
                        Text("Log In")
                            .foregroundColor(Color.green)
                    }
                }
                .padding(.top, 20)
            }
            .padding()
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.height > 50 {
                            // Swipe down detected
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
            )
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .background(Color.black.opacity(0.8))
                    .clipShape(Circle())
                    .frame(width: 80, height: 80)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarHidden(true)
    }
    
    private func signUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        isLoading = true
        authManager.signUp(email: email, password: password) { success in
            if success {
                // Once signed up, store user information in the Realtime Database
                addUserToDatabase()
            } else {
                isLoading = false
                errorMessage = "Sign Up failed. Please try again."
            }
        }
    }
    
    private func addUserToDatabase() {
        guard let user = Auth.auth().currentUser else {
            isLoading = false
            errorMessage = "User not found after sign up."
            return
        }
        
        let ref = Database.database().reference()
        let userData = [
            "name": name,
            "email": email,
          //  "username": email.components(separatedBy: "@").first ?? "", // Derive username from email
            "username":name,
            "today_mileage": 0,
            "weekly_mileage": 0,
            "monthly_mileage": 0,
            "yearly_mileage": 0,
            "today_minutes": 0,
            "weekly_minutes": 0,
            "monthly_minutes": 0,
            "yearly_minutes": 0,
            "fastest_all_time_speed": 0
        ] as [String : Any]
        
        ref.child("users").child(user.uid).setValue(userData) { error, _ in
            isLoading = false
            if let error = error {
                errorMessage = "Failed to save user data: \(error.localizedDescription)"
            } else {
                isSignedUp = true
                // Optionally navigate to another screen or show a success message
            }
        }
    }
}

struct SignUpScreen_Previews: PreviewProvider {
    static var previews: some View {
        SignUpScreen()
            .environmentObject(AuthManager())
    }
}
