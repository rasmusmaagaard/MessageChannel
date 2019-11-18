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
    @Published var username : String = ""
    @Published var messages = [ChatMessage]()
    
    init() {
        setupActionCableConnection()
        actionCableClient.connect()
        
        // Add "welcome message" visible when starting the chatroom
        addMessage(
            sender: "Rails",
            content: "Welcome to the ActionCable study. The server is written in Rails 6 and has a web client (using javascript and handlebar).",
            remote: true)
        addMessage(
            sender: "iOS",
            content: "The swift client is written in Swift 5.",
            remote: true)
        addMessage(
            sender: "iOS",
            content: "Oh, by the Way. The UI is written using SwiftUI and a bit of Combine 😎",
            remote: true)
        addMessage(
            sender: "macOS",
            content: "Catalyst is working like a dream! 🤩",
            remote: true)
    }
        
    // Create a ChatMessage object and store it (in memory only). When appending the message to the @published list
    // the SwiftUI will automatically update.
    private func addMessage(sender: String, content: String, remote: Bool) {
        // TODO: Curently remote status is used for selecting color. It should be user selectable.
        var message = ChatMessage(
                        sender: sender,
                        content: content,
                        color: remote ? .green : .blue,
                        remote: remote,
                        showSenderInfo: remote)
        
        // Only show sender information for the first message in a series of messages from the same sender (with the
        // current simple user/sender model we can not seperate two users with the same sender name).
        // Only show sender information for remote users.
        if let previousMessage = messages.last, remote  {
            message.showSenderInfo = previousMessage.sender != message.sender
        }
        
        // Update the UI
        messages.append(message)
    }
    
    // Fill in the sender infomation and forward it to the Action Cable client
    // TODO: The color should also be user selectable and added here!
    func sendMessage(_ message: String) {
        broadcastChatMessage(sender: username, content: message)
    }
}

// MARK: ActionCable client methods

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

        // Here we get data from Action Cable. If the data is accepted we create a new (local) message and update the UI.
        actionCableChannel?.onReceive = { (data: Any?, error: Error?) in
            if let error = error {
                print("ERROR: Unable to receive message from ActionCable Channel: \(error.localizedDescription)")
                return
            }

            // Extract the expected data from the JSON message. If expected data is missing we do nothing. If the data
            // is OK we create a new message.
            if let message = data as? [String: Any],
               let sender = message["sender"] as? String,
               let content = message["content"] as? String {
                self.addMessage(sender: sender, content: content, remote: sender != self.username)
            }
        }
    }

    // This method will call the 'broadcast' method on the Action Cable Channel Controller (defined in the Rails server
    // project). The remote method will create a new message and broadcast it back to all clients. This include the
    // sending client. Because of this we do not create a local message - we wait for the message to come back and add
    // the message in the above 'onReceive' callback.
    func broadcastChatMessage(sender: String, content: String) {
        let broadcastAction = "broadcast"
        
        // We do not send empty messages..
        let trimmedMessage = content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if !trimmedMessage.isEmpty {
            print("Sending ActionCable message: \(ActionCableController.ChannelIdentifier)#\(broadcastAction)")
            
            let channelMessage = ["sender": sender, "content": trimmedMessage]
            actionCableChannel?.action(broadcastAction, with: channelMessage)
        }
    }
}
