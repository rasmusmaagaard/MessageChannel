//
//  ActionCableController.swift
//  MessageChannel
//
//  Created by Rasmus Maagaard on 15/11/2019.
//  Copyright © 2019 RM. All rights reserved.
//

import SwiftUI

// Structure representing a message
struct ChatMessage : Hashable {
    var sender: String
    var content: String
    var color: Color
    var remote: Bool
    var showSenderInfo: Bool
}

// ObservableObject so SwiftUI can access it.
class ActionCableController : ObservableObject {
    // @Published so the ContentView is notified when it changes
    @Published var messages = [ChatMessage]()
    
    init() {
        addMessage(sender: "User A", content: "Hello world", remote: true)
        addMessage(sender: "User B", content: "This is my first swiftUI app", remote: false)
        addMessage(sender: "User A", content: "No worries!", remote: true)
        addMessage(sender: "User A", content: "Talk to you later 🤠", remote: true)
        addMessage(sender: "User B", content: "L8 😬", remote: false)
    }
    
    func sendMessage(_ message: String) {
        addMessage(sender: "SwiftUI", content: message, remote: false)
    }
    
    private func addMessage(sender: String, content: String, remote: Bool) {
        //TODO Curently remote status is used for selecting color. It should be user selectable.
        var message = ChatMessage(
                        sender: sender,
                        content: content,
                        color: remote ? .green : .blue,
                        remote: remote,
                        showSenderInfo: remote)
        
        // Only show sender information for the first message in a series of messages from the same sender.
        // Only show sender infomation for remote users.
        if let previousMessage = messages.last, remote  {
            message.showSenderInfo = previousMessage.sender != message.sender
        }
        
        messages.append(message)
    }
}
