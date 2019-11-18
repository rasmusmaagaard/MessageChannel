//
//  ContentView.swift
//  MessageChannel
//
//  Created by Rasmus Maagaard on 15/11/2019.
//  Copyright © 2019 RM. All rights reserved.
//

import SwiftUI
import Combine

// This is the main view. The interface is implemented using only SwiftUI.
// SwiftUI is a new framework and is missing a lot of functionality we expect coming from UIKit.
// As a study project this is acceptable. And it has been shown that a lot can be done using only SwiftUI.
// In larger project it will need to integrate with UIKit - which is supported by SwiftUI.
// TODO: SwiftUI List can not be scrolled programatically :( We must wrap UIKit or implement a "scroll component" from
// scratch in SwiftUI. For now the user need to scroll manually to see the latest updates.
struct ContentView: View {
    // The Action Cable Controller is injected in SceneDelegate
    @EnvironmentObject var actionCableController: ActionCableController
    
    // The main view
    var body: some View {
        Group {
            if actionCableController.username.isEmpty {
                SignInView()
            } else {
                ChatRoomView()
            }
        // Enable "full screen" view for iPad and macOS (default is a split view)
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: SwiftUI - Sign in view

struct SignInView : View {
    @EnvironmentObject var actionCableController: ActionCableController
    // @state makes it possible to update values inside a struct and the value is observed by the the SwiftUI. When the
    // value changes the UI is updated.
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
                // Username should be at least 4 chars long
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
    
    // Action for the send button and called when the user tap/press the enter key
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

// SwiftUI does not (yet) support adjusting views when the soft keyboard is show/hidden. This view modifier add this
// feature.
// We use Combine (Apple's FRP framework) to setup a stream which merges 3 notification center steams. The streams
// publish changes to height of the keyboard.
// We subscribe to this stream and update the currentKeyboard @state when a new keyboard height is published.
// When the @state value changes SwiftUI update the UI and we get a chance to update the padding on the modified view.
// Inspiration to solution: https://stackoverflow.com/a/58402607
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
    // Because of this we only use the height of the keyboard.
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
