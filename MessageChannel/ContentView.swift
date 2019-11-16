//
//  ContentView.swift
//  MessageChannel
//
//  Created by Rasmus Maagaard on 15/11/2019.
//  Copyright © 2019 RM. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var actionCableController: ActionCableController
    @State var newMessage: String = ""
    
    init() {
        // To remove separators from SwiftUI list
        // https://stackoverflow.com/a/58426643
        UITableView.appearance().separatorStyle = .none
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(actionCableController.messages, id: \.self) { message in
                        MessageView(message: message)
                    }
                }.navigationBarTitle("Chat Room")
                
                HStack {
                    TextField("New message...", text: $newMessage).textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Send", action: sendMessage)
                }.padding()
            }
        }
            
        // Enable "full screen" view for iPad and macOS (default is a splitview)
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func sendMessage() {
        actionCableController.sendMessage(newMessage)
        newMessage = ""
    }
}

// A "cell" structure for the messages
struct MessageView : View {
    var message: ChatMessage
    
    var body: some View {
        HStack {
            if message.remote {
                // Push remote (other users) messages to the right side of the screen.
                Spacer()
            }
            VStack(alignment: message.remote ? .trailing : .leading) {
                if message.showSenderInfo {
                    Text(message.sender)
                        .fontWeight(.thin)
                        .italic()
                }
                Text(message.content)
                    .bold()
                    .padding(10)
                    .foregroundColor(Color.white)
                    .background(message.color)
                    .cornerRadius(10)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            // The preview is not using the scene delegate. This gives the preview access to an ActionCable controller
            .environmentObject(ActionCableController())
    }
}
