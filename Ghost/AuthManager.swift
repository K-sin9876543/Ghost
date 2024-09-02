//
//  AuthManager.swift
//  Ghost
//
//  Created by Kabir on 9/2/24.
//
import SwiftUI
import FirebaseAuth

class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    
    init() {
        self.isLoggedIn = Auth.auth().currentUser != nil
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if error != nil {
                completion(false)
                return
            }
            self.isLoggedIn = true
            completion(true)
        }
    }
    
    func signUp(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if error != nil {
                completion(false)
                return
            }
            self.isLoggedIn = true
            completion(true)
        }
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        self.isLoggedIn = false
    }
}
