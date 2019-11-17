//
//  ContentView.swift
//  MessageChannel
//
//  Created by Rasmus Maagaard on 15/11/2019.
//  Copyright © 2019 RM. All rights reserved.
//

import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var actionCableController: ActionCableController
    
    var body: some View {
        Group {
            if actionCableController.username.isEmpty {
                SignInView()
            } else {
                ChatRoomView()
            }
        // Enable "full screen" view for iPad and macOS (default is a splitview)
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: SwiftUI - Sign in view

struct SignInView : View {
    @EnvironmentObject var actionCableController: ActionCableController
    @State var name: String = ""
    
    var body: some View {
        VStack {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
            Spacer()
            Group {
                TextField("Enter usernamer...", text: $name) {
                    self.actionCableController.username = self.name
                }.textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Start chat") {
                    self.actionCableController.username = self.name
                }.disabled(name.count <= 3)
            }
            Spacer()
        }.padding().modifier(AdaptsToSoftwareKeyboard())
    }
}

// MARK: SwiftUI - Chat view

struct ChatRoomView : View {
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
                    TextField("New message...", text: $newMessage) {
                        self.sendMessage()
                    }.textFieldStyle(RoundedBorderTextFieldStyle()).keyboardType(.twitter)
                    Button("Send", action: sendMessage)
                }.padding()
            }.modifier(AdaptsToSoftwareKeyboard())
        }
    }
    
    func sendMessage() {
        actionCableController.sendMessage(newMessage)
        newMessage = ""
    }
}

// MARK: SwiftUI - Message view

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

// MARK: SwiftUI - Preview Provider

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            // The preview is not using the scene delegate. This gives the preview access to an ActionCable controller
            .environmentObject(ActionCableController())
    }
}

// MARK: SwiftUI - Soft Keyboard View modifier

// SwiftUI does not (yet) support adjusting views when the soft keyboard is show/hidden.
// This view modifer add this feature. Inspiration to solution: https://stackoverflow.com/a/58402607
struct AdaptsToSoftwareKeyboard: ViewModifier {
    @State var currentKeyboard: SoftKeyboardAnimation = SoftKeyboardAnimation(height: 0)
    
    // It is not (yet) possible to create a SwiftUI Animation from a UIViewAnimationCurve value.
    // Because of this limitation we have to hardcode an animation style to use.
    // Inspiration for animation values: https://stackoverflow.com/a/42904976
    struct SoftKeyboardAnimation {
        let height: CGFloat
        let animation: Animation = .interpolatingSpring(
                                     mass: 3,
                                     stiffness: 1000,
                                     damping: 500,
                                     initialVelocity: 0)
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, currentKeyboard.height)
            .edgesIgnoringSafeArea(currentKeyboard.height == 0 ? Edge.Set() : .bottom)
            .onAppear(perform: subscribeToKeyboardEvents)
            .animation(currentKeyboard.animation)
    }
    
    // We are unable to use keyboardAnimationDurationUserInfoKey and keyboardAnimationCurveUserInfoKey.
    // Because of this we only look for the height of the keyboard.
    private let keyboardWillChange = NotificationCenter.default
        .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
        .map { $0.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect }
        .map { SoftKeyboardAnimation(height: $0.height) }
    
    private let keyboardWillOpen = NotificationCenter.default
        .publisher(for: UIResponder.keyboardWillShowNotification)
        .map { $0.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect }
        .map { SoftKeyboardAnimation(height: $0.height) }

    private let keyboardWillHide =  NotificationCenter.default
        .publisher(for: UIResponder.keyboardWillHideNotification)
        .map { _ in SoftKeyboardAnimation(height: 0) }

    private func subscribeToKeyboardEvents() {
        _ = Publishers.Merge3(keyboardWillChange, keyboardWillOpen, keyboardWillHide)
            .subscribe(on: RunLoop.main)
            .assign(to: \.self.currentKeyboard, on: self)
    }
}
