//
//  NotificationScreen.swift
//  Ghost
//
//  Created by Kabir on 9/4/24.
//

import Foundation

import Firebase
import SwiftUI
import FirebaseAuth

struct NotificationScreen: View {
    @State private var friendRequests: [User] = []
    @State private var isLoading: Bool = false
    @State private var selectedColor: Color

    init() {
        _selectedColor = State(initialValue: ThemeManager().accentColor)
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .padding()
            } else if friendRequests.isEmpty {
                Text("No friend requests")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(friendRequests) { user in
                    HStack {
                        Text(user.username)
                            .foregroundColor(selectedColor)
                        Spacer()
                        Button(action: {
                            handleFriendRequest(accepted: true, for: user)
                        }) {
                            Text("Accept")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green.opacity(0.8))
                                .cornerRadius(10)
                        }
                        Button(action: {
                            handleFriendRequest(accepted: false, for: user)
                        }) {
                            Text("Deny")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .navigationTitle("Friend Requests")
        .onAppear {
            fetchFriendRequests()
        }
    }

    private func fetchFriendRequests() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("Error: No logged in user")
            return
        }
        isLoading = true
        
        let ref = Database.database().reference().child("friend_requests").child(currentUserId)
        ref.observeSingleEvent(of: .value) { snapshot in
            isLoading = false
            guard snapshot.exists(), let requestsData = snapshot.value as? [String: [String: Any]] else {
                print("No friend requests found")
                self.friendRequests = []
                return
            }
            
            var requests: [User] = []
            let group = DispatchGroup()
            
            for (friendId, requestDetails) in requestsData {
                if let status = requestDetails["status"] as? String, status == "pending" {
                    group.enter()
                    let userRef = Database.database().reference().child("users").child(friendId)
                    userRef.observeSingleEvent(of: .value) { userSnapshot in
                        if let userData = userSnapshot.value as? [String: Any],
                           let username = userData["username"] as? String,
                           let email = userData["email"] as? String {
                            requests.append(User(uid: friendId, username: username, email: email))
                        }
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.friendRequests = requests
                print("Fetched \(requests.count) friend requests")
            }
        } withCancel: { error in
            self.isLoading = false
            print("Failed to fetch friend requests: \(error.localizedDescription)")
        }
    }

    private func handleFriendRequest(accepted: Bool, for user: User) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let requestRef = Database.database().reference().child("friend_requests").child(currentUserId).child(user.uid)
        
        if accepted {
            // Update friend request status and add to friends list
            requestRef.removeValue { error, _ in
                if let error = error {
                    print("Failed to remove friend request: \(error.localizedDescription)")
                    return
                }
                addFriend(user: user)
            }
        } else {
            // Remove friend request if denied
            requestRef.removeValue { error, _ in
                if let error = error {
                    print("Failed to remove friend request: \(error.localizedDescription)")
                }
                fetchFriendRequests()
            }
        }
    }

    private func addFriend(user: User) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let friendsRef = Database.database().reference().child("friends")
        
        // Add each other as friends
        let currentUserData = ["username": Auth.auth().currentUser?.displayName ?? "Unknown", "email": Auth.auth().currentUser?.email ?? ""]
        let friendUserData = ["username": user.username, "email": user.email]
        
        let group = DispatchGroup()
        
        group.enter()
        friendsRef.child(currentUserId).child(user.uid).setValue(friendUserData) { error, _ in
            if let error = error {
                print("Failed to add friend to current user: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        group.enter()
        friendsRef.child(user.uid).child(currentUserId).setValue(currentUserData) { error, _ in
            if let error = error {
                print("Failed to add current user to friend: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            print("Friend added successfully")
            fetchFriendRequests() // Refresh friend requests
        }
    }
}
