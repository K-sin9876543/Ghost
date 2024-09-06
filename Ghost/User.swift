//
//  User.swift
//  Ghost
//
//  Created by Kabir on 9/4/24.
//

import Foundation
import SwiftUI

struct User: Identifiable {
    let id = UUID()
    let uid: String
    let username: String
    let email: String
}
