//
//  HomeScreen.swift
//  Ghost
//
//  Created by Kabir on 9/2/24.
//
//
import SwiftUI

import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack {
            Text("Home Screen")
                .font(.largeTitle)
                .padding()
            
            Button(action: {
                authManager.signOut()
            }) {
                Text("Sign Out")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
            .environmentObject(AuthManager())
    }
}
