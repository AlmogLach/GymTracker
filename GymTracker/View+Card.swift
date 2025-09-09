//
//  View+Card.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import SwiftUI

struct AppCardModifier: ViewModifier {
    let padding: CGFloat
    
    init(padding: CGFloat = AppTheme.s16) {
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.cardBG)
            .cornerRadius(AppTheme.r16)
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
            .padding(.horizontal, AppTheme.s16)
    }
}

struct SectionHeaderModifier: ViewModifier {
    let title: String
    let trailing: AnyView?
    
    init(title: String, trailing: (() -> AnyView)? = nil) {
        self.title = title
        self.trailing = trailing?()
    }
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.s8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if let trailing = trailing {
                    trailing
                }
            }
            
            content
        }
    }
}

extension View {
    func appCard(padding: CGFloat = AppTheme.s16) -> some View {
        modifier(AppCardModifier(padding: padding))
    }
    
    func sectionHeader(_ title: String, trailing: (() -> AnyView)? = nil) -> some View {
        modifier(SectionHeaderModifier(title: title, trailing: trailing))
    }
}
