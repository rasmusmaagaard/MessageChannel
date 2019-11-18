# Swift chat client for Action Cable study project
This is a "chat client" written to learn how to connect a Swift client to Rails server using ActionCable (websocket).

[![Screenshot](Documentation/Screenshots/SwiftClient.gif?raw=true)](Documentation/Screenshots/SwiftClient.mp4?raw=true "Swift Client")

## Overview
When running the client it will try to connect to a websocket at <ws://localhost:3000/cable>. When successful it will try to subscribe to an Action Cable Channel (RoomChannel).

The goal of this project was to learn. Because of this all of the UI is written in [SwiftUI](https://developer.apple.com/documentation/swiftui) and the project also uses a little bit of [Combine](https://developer.apple.com/documentation/combine).

The client can run on iPhone, iPad and as a native macOS app using [Catalyst](https://developer.apple.com/documentation/uikit/mac_catalyst?language=objc) :gift:

Websocket connection is hadled by [StarScream](https://github.com/daltoniam/Starscream) indirectly using an updated fork of [ActionCableClient](https://github.com/ahbou/Swift-ActionCableClient). It was out of scope to use the new [native websocket](https://developer.apple.com/documentation/foundation/nsurlsessionwebsockettask?language=objc) interface.

### Limitations
SwiftUI. This is a new framework and really great, but a lot of functionality from UIKit is missing. Most can be solved by wrapping UIKit or reimplement components from scratch. In this project the largest shortcoming is the lack of being able to scroll a list. This can only be done by the user manually. The consequence is the user has to scroll down to see new messages..

A couple of workarounds is possible, but not implemented in this study project :innocent:

The Swift client does not support colors for the chatbubbles. The users own are blue and other users are always green.

**NOTE: The client is hardcoded to localhost:3000 and can only be run on the simulator with this configuration.**

### Requirements
The project is using Swift 5 and SwiftUI and requires Xcode 11. macOS Catalina is needed to make live preview of SwiftUI work in Xcode. [CocoaPods](https://cocoapods.org) is used to install dependencies and must be install.

### Usage
Clone the project, install dependencies and run the simulator :neckbeard:
```
git clone git@github.com:rasmusmaagaard/MessageChannel.git
cd MessageChannel
pod install
open MessageChannel.xcworkspace
```
If the [Rails backend](https://github.com/rasmusmaagaard/MessageChannel) is setup and running on the same machine you are ready to chat :speech_balloon:

Common errors - The error handling is minimal and the UX could be improved :skull:
* Username must be at least 4 characters long
* The server isn't running


*Sometime the Swift compile comes up with a error about a missing module. It often help to clean the project or change targets..*

### Acknowledgements
* [The app icon](https://www.flaticon.com/free-icon/chat_230367)

### Final notes
As this is a study project with time constraints there is currently no tests and only minimal error handling :scream::rage::cry:

### TODO
- [ ] [Content scrolling in messages view](https://blog.process-one.net/writing-a-custom-scroll-view-with-swiftui-in-a-chat-application/)
- [ ] Release focus from text field when using 'send button'. Is this possible using only SwiftUI?
- [ ] Add tests
- [ ] Add error handling
- [ ] Select color for chat bubbles 
- [ ] Support for servers not running on localhost
