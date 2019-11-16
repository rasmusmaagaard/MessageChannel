//
//  ActionCableController.swift
//  MessageChannel
//
//  Created by Rasmus Maagaard on 15/11/2019.
//  Copyright © 2019 RM. All rights reserved.
//

import SwiftUI
import ActionCableClient

struct ChatMessage : Hashable {
    var sender: String
    var content: String
    var color: Color
    var remote: Bool
    var showSenderInfo: Bool
}

// ObservableObject so SwiftUI can react when it changes.
class ActionCableController : ObservableObject {
    let actionCableClient = ActionCableClient(url: URL(string: "ws://localhost:3000/cable")!)
    var actionCableChannel: Channel?

    // @Published so the ContentView is notified when it changes
    @Published var messages = [ChatMessage]()
    
    init() {
        setupActionCableConnection()
        actionCableClient.connect()
        
        addMessage(sender: "User A", content: "Hello world", remote: true)
        addMessage(sender: "User B", content: "This is my first swiftUI app", remote: false)
        addMessage(sender: "User A", content: "No worries!", remote: true)
        addMessage(sender: "User A", content: "Talk to you later 🤠", remote: true)
        addMessage(sender: "User B", content: "L8 😬", remote: false)
    }
    
    func sendMessage(_ message: String) {
        broadcastChatMessage(sender: "SwiftUI", content: message)
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

// MARK: ActionCableClient

extension ActionCableController {
    static var ChannelIdentifier = "RoomChannel"
    
    func setupActionCableConnection() {
        actionCableClient.willConnect = {
            print("Connecting to Rails ActionCable...")
        }

        actionCableClient.onConnected = {
            print("Connected to Rails ActionCable: \(self.actionCableClient.url)")
            self.connectToChannel()
        }

        actionCableClient.onDisconnected = { (error: ConnectionError?) in
            print("Disconected from Rails Action Cable. Reason: \(String(describing: error))")
        }

        actionCableClient.willReconnect = {
            print("Reconnecting to Rails ActionCable: \(self.actionCableClient.url)")
            return true
        }
    }

    func connectToChannel() {
        print("Connecting to ActionCable Channel...")
        actionCableChannel = actionCableClient.create(ActionCableController.ChannelIdentifier, parameters: nil)
        
        actionCableChannel?.onSubscribed = {
            print("Subscribed ActionCable Channel: \(ActionCableController.ChannelIdentifier)")
        }

        actionCableChannel?.onReceive = { (data: Any?, error: Error?) in
            if let error = error {
                print("ERROR: Unable to receive message from ActionCable Channel: \(error.localizedDescription)")
                return
            }

            if let message = data as? [String: Any],
               let sender = message["sender"] as? String,
               let content = message["content"] as? String {
                 self.addMessage(sender: sender, content: content, remote: sender != "SwiftUI")
            }
        }
    }

    func broadcastChatMessage(sender: String, content: String) {
        let broadcastAction = "broadcast"
        
        let trimmedMessage = content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if !trimmedMessage.isEmpty {
            print("Sending ActionCable message: \(ActionCableController.ChannelIdentifier)#\(broadcastAction)")
            
            let channelMessage = ["sender": sender, "content": trimmedMessage]
            actionCableChannel?.action(broadcastAction, with: channelMessage)
        }
    }
}
