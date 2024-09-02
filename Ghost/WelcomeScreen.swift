//
//  ContentView.swift
//  Ghost
//
//  Created by Kabir on 9/2/24.
//

import SwiftUI

struct WelcomeScreen: View {
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(.systemBackground)]), // Transition from black to system background color
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.white) // Icon color
                    .padding(.bottom, 20)
                
                Text("Welcome to Ghost")
                    .font(.system(size: 34, weight: .bold, design: .rounded)) // Title font
                    .foregroundColor(.white) // Text color
                    .padding(.bottom, 20)
                
                Text("Track your journeys and performance with ease")
                    .font(.system(size: 18, weight: .medium, design: .rounded)) // Subtitle font
                    .foregroundColor(.white) // Text color
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
                
//                 Sign Up Button
                NavigationLink(destination: SignUpScreen()) {
                    Text("Sign Up")
                        .font(.system(size: 18, weight: .semibold, design: .rounded)) // Button font
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.8)) // Accent color with transparency
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                
                // Login Button
//                NavigationLink(destination: LoginScreen()) {
//                    Text("Login")
//                        .font(.system(size: 18, weight: .semibold, design: .rounded)) // Button font
//                        .foregroundColor(.black)
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(Color.green.opacity(0.8)) // Accent color with transparency
//                        .cornerRadius(10)
//                }
                .padding(.horizontal, 20)
            }
            .padding()
        }
    }
}



#Preview {
    WelcomeScreen()
}
