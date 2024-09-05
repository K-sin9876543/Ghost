//
//  Color.swift
//  Ghost
//
//  Created by Kabir on 9/2/24.
//

import SwiftUI

class ThemeManager: ObservableObject {
    @Published var accentColor: Color
    
    init() {
        // Set the accent color by loading from defaults or use a default color
        self.accentColor = ThemeManager.loadColorFromDefaults() ?? .green
    }
    
    private func saveColorToDefaults(color: Color) {
        let uiColor = UIColor(color)
        let colorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
        UserDefaults.standard.set(colorData, forKey: "accentColor")
    }
    
    private static func loadColorFromDefaults() -> Color? {
        guard let colorData = UserDefaults.standard.data(forKey: "accentColor"),
              let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor else {
            return nil
        }
        return Color(uiColor)
    }
    
    func updateAccentColor(to color: Color) {
        accentColor = color
        saveColorToDefaults(color: color)
    }
}
