//
//  HowToPlay.swift
//  CODElonize
//
//  Created by Nadila Rizky Amelia on 09/07/26.
//

import SwiftUI

struct HowToPlayStep: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let description: String
}

struct HowToPlayRule: Identifiable {
    let id = UUID()
    let title: String
    let description: String
}

struct HowToPlayCard: View {
    let onClose: () -> Void
    
    private let steps: [HowToPlayStep] = [
        .init(number: 1, title: "Join the lobby", description: "Host a game or enter a room code to play with friends."),
        .init(number: 2, title: "Place the island", description: "Players place the AR island, then everyone taps Ready."),
        .init(number: 3, title: "Choose a territory", description: "Tap area to answer a question."),
        .init(number: 4, title: "Answer fast", description: "Answer correctly and quickly to conquer the territory."),
        .init(number: 5, title: "Conquer territories", description: "A faster correct answer can steal a territory from another player."),
        .init(number: 6, title: "Use power-ups", description: "Find one power-ups and use Earthquake, Tsunami, or Pocket Watch.")
    ]
    
    private let rules: [HowToPlayRule] = [
        .init(title: "5-minute match", description: "Conquer as many territories as possible."),
        .init(title: "One attempt per territory", description: "Each player can answer each area only once."),
        .init(title: "Fastest correct answer wins", description: "speed matters!")
    ]
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.themeCream)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white, lineWidth: 4)
                )
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    StrokedText(
                        text: "HOW TO PLAY?",
                        font: .custom("Luckiest Guy", size: 32),
                        fillColor: .white,
                        strokeColor: .themeDarkTeal,
                        strokeWidth: 2
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(steps) { step in
                            howToPlayRow(number: "\(step.number).", title: step.title, description: step.description)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Important rules")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.themeBrown)
                        
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(rules) { rule in
                                howToPlayRow(number: "✦", title: rule.title, description: rule.description)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(24)
            }
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.themeBrown)
                    .padding(12)
            }
        }
        .frame(maxWidth: 340, maxHeight: 560)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    private func howToPlayRow(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.themeBrown)
                .frame(width: 20, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.themeBrown)
                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.themeBrown.opacity(0.8))
            }
        }
    }
}

#Preview {
    ZStack {
        Color.themeDarkTeal.edgesIgnoringSafeArea(.all)
        HowToPlayCard(onClose: {})
    }
}
