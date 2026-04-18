//
//  AIChatView.swift
//  BhittePatroApp
//
//  Created by Pranab Kc on 18/04/2026.
//

import SwiftUI

// MARK: - Models and Helper Views
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    var options: [String] = []
    let isUser: Bool
}

struct ChatBubble: View {
    let message: ChatMessage
    let onOptionTapped: (String) -> Void
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading) {
            Text(message.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.isUser ? Color.red.opacity(0.9) : Color.secondary.opacity(0.15))
                .foregroundStyle(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            if !message.options.isEmpty {
                HStack {
                    ForEach(message.options, id: \.self) { option in
                        Button(action: { onOptionTapped(option) }) {
                            Text(option)
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.8))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
}

// MARK: - AI Chat View
struct AIChatView: View {
    @State private var messages: [ChatMessage] = [
        .init(text: "नमस्ते! How can I assist you with the calendar today?", isUser: false)
    ]
    @State private var inputText: String = ""
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(spacing: 12) {
                        ForEach(messages) { message in
                            ChatBubble(message: message, onOptionTapped: handleOption)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .onChange(of: messages.count) {
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            inputBar
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 32, height: 32)
                    .background(Color.secondary.opacity(0.1), in: Circle())
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 1) {
                Text("Calendar AI")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text("Online")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.green)
            }
            .padding(.leading, 6)
            
            Spacer()
        }
        .padding()
    }
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask something...", text: $inputText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .frame(height: 38)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            Button(action: { sendMessage(text: inputText) }) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 38, height: 38)
                    .background(Color.red, in: Circle())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(inputText.isEmpty)
        }
        .padding()
    }
    
    private func handleOption(option: String) {
        sendMessage(text: option, isSilent: true)
    }
    
    private func sendMessage(text: String, isSilent: Bool = false) {
        guard !text.isEmpty else { return }
        
        if !isSilent {
            let userMessage = ChatMessage(text: text, isUser: true)
            messages.append(userMessage)
        }
        
        inputText = ""
        
        // Disable options on previous messages
        if messages.count > 1 {
            for i in 0..<(messages.count - 1) {
                messages[i].options = []
            }
        }
        
        let aiResponseText = AIResponseGenerator.shared.generateResponse(for: text)
        var options: [String] = []
        var responseText = aiResponseText
        
        if let range = aiResponseText.range(of: "CHAT_OPTIONS:") {
            responseText = String(aiResponseText[..<range.lowerBound])
            let optionsString = String(aiResponseText[range.upperBound...]).trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            options = optionsString.components(separatedBy: ",")
        }
        
        let aiResponse = ChatMessage(text: responseText, options: options, isUser: false)
        messages.append(aiResponse)
    }
}
