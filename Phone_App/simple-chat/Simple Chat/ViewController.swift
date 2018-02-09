/**
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import UIKit
import JSQMessagesViewController
//import OpenWeatherSwift
import OpenWeatherSwift
//import openweathermap_swift_sdk
import AVFoundation
import ConversationV1
import SpeechToTextV1
import TextToSpeechV1


class ViewController: JSQMessagesViewController {
    
    var messages = [JSQMessage]()
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    
    var conversation: Conversation!
    var speechToText: SpeechToText!
    var textToSpeech: TextToSpeech!
    
    var audioPlayer: AVAudioPlayer?
    var workspace = Credentials.ConversationWorkspace
    var context: Context?
    
    var speech = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInterface()
        setupSender()
        setupWatsonServices()
        startConversation()
    }
}

// MARK: Watson Services
extension ViewController {
    
    /// Instantiate the Watson services
    func setupWatsonServices() {
        conversation = Conversation(
            username: Credentials.ConversationUsername,
            password: Credentials.ConversationPassword,
            version: "2018-02-01"
        )
        speechToText = SpeechToText(
            username: Credentials.SpeechToTextUsername,
            password: Credentials.SpeechToTextPassword
        )
        textToSpeech = TextToSpeech(
            username: Credentials.TextToSpeechUsername,
            password: Credentials.TextToSpeechPassword
        )
    }
    
    /// Present an error message
    func failure(error: Error) {
        let alert = UIAlertController(
            title: "Watson Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    /// Start a new conversation
    func startConversation() {
        conversation.message(
            workspaceID: workspace,
            failure: failure,
            success: presentResponse
        )
    }
    
    /*func getWeather() -> String {
        var result = ""

        OpenWeatherMapClient.client(appID: "ed9049dc12e1698ee3b17de097abadaa")
        print (OpenWeatherMapClient.accessibilityActivate())
        OpenWeatherMapAPIClient.client.getWeather(cityName: "") { (weatherData, error) in
            if error == nil && weatherData!.code == "200" {
                print(weatherData!.code)
            }
        }
        return result
    }*/
    
   func getWeather() -> String {
        var output = ""
        let client = OpenWeatherSwift(apiKey: "ed9049dc12e1698ee3b17de097abadaa", temperatureFormat: .Celsius)
        client.currentWeatherByCity(name: "London") {results in
            let weather = Weather2.init(data: results)
            output = "The Temperature is " + (String) (weather.temperature) + "celsius"
        }
        return output
    }
    
    /// Present a conversation reply and speak it to the user
    func presentResponse(_ response: MessageResponse) {
        
        if ((response.intents.count > 0) && (response.intents[0].intent == "weather")){
            
        }
        
        //var tmp = getWeather()
        
        
        let text = response.output.text.joined()
        context = response.context // save context to continue conversation
        
        // synthesize and speak the response
        textToSpeech.synthesize(text, failure: failure) { audio in
            self.audioPlayer = try! AVAudioPlayer(data: audio)
            self.audioPlayer?.prepareToPlay()
            self.audioPlayer?.play()
        }
        
        // create message
        let message = JSQMessage(
            senderId: User.watson.rawValue,
            displayName: User.getName(User.watson),
            text: text
        )
        
        // add message to chat window
        if let message = message {
            self.messages.append(message)
            DispatchQueue.main.async { self.finishSendingMessage() }
        }
    }
    
    /// Start transcribing microphone audio
    @objc func startTranscribing() {
        audioPlayer?.stop()
        self.speech = ""
        var settings = RecognitionSettings(contentType: .opus)
        settings.interimResults = true
        speechToText.recognizeMicrophone(settings: settings, failure: failure) { results in
            self.speech = results.bestTranscript
            print(results.bestTranscript)
        }
    }
    
    /// Stop transcribing microphone audio
    @objc func stopTranscribing() {
        speechToText.stopRecognizeMicrophone()
        let message = JSQMessage(senderId: User.me.rawValue, displayName: User.getName(User.me), text: self.speech)
        self.messages.append(message!)
        self.finishSendingMessage(animated: true)
        
        // send text to conversation service
        let input = InputData(text: self.speech)
        let request = MessageRequest(input: input, context: context)
        conversation.message(
            workspaceID: workspace,
            request: request,
            failure: failure,
            success: presentResponse
        )
    }
}

// MARK: Configuration
extension ViewController {
    
    func setupInterface() {
        // bubbles
        let factory = JSQMessagesBubbleImageFactory()
        let incomingColor = UIColor.jsq_messageBubbleBlue()
        let outgoingColor = UIColor.jsq_messageBubbleRed()
        incomingBubble = factory!.incomingMessagesBubbleImage(with: incomingColor)
        outgoingBubble = factory!.outgoingMessagesBubbleImage(with: outgoingColor)
        
        // avatars
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        // microphone button
        let microphoneButton = UIButton(type: .custom)
        microphoneButton.frame = CGRect(x: 137, y: 493, width: 46, height: 30)
        microphoneButton.setImage(#imageLiteral(resourceName: "microphone-hollow"), for: .normal)
        microphoneButton.setImage(#imageLiteral(resourceName: "microphone"), for: .highlighted)
        microphoneButton.addTarget(self, action: #selector(startTranscribing), for: .touchDown)
        microphoneButton.addTarget(self, action: #selector(stopTranscribing), for: .touchUpInside)
        microphoneButton.addTarget(self, action: #selector(stopTranscribing), for: .touchUpOutside)
        self.view.addSubview(microphoneButton)
        inputToolbar.removeFromSuperview()
    }
    
    func setupSender() {
        senderId = User.me.rawValue
        senderDisplayName = User.getName(User.me)
    }
    
    /*override func didPressSend(
        _ button: UIButton!,
        withMessageText text: String!,
        senderId: String!,
        senderDisplayName: String!,
        date: Date!)
    {
        let message = JSQMessage(
            senderId: User.me.rawValue,
            senderDisplayName: User.getName(User.me),
            date: date,
            text: text
        )
        
        if let message = message {
            self.messages.append(message)
            self.finishSendingMessage(animated: true)
        }
        
        // send text to conversation service
        let input = InputData(text: text)
        let request = MessageRequest(input: input, context: context)
        conversation.message(
            workspaceID: workspace,
            request: request,
            failure: failure,
            success: presentResponse
        )
    }*/
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        // required by super class
    }
}

// MARK: Collection View Data Source
extension ViewController {
    
    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int)
        -> Int
    {
        return messages.count
    }
    
    override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        messageDataForItemAt indexPath: IndexPath!)
        -> JSQMessageData!
    {
        return messages[indexPath.item]
    }
    
    override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        messageBubbleImageDataForItemAt indexPath: IndexPath!)
        -> JSQMessageBubbleImageDataSource!
    {
        let message = messages[indexPath.item]
        let isOutgoing = (message.senderId == senderId)
        let bubble = (isOutgoing) ? outgoingBubble : incomingBubble
        return bubble
    }
    
    override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        avatarImageDataForItemAt indexPath: IndexPath!)
        -> JSQMessageAvatarImageDataSource!
    {
        let message = messages[indexPath.item]
        return User.getAvatar(message.senderId)
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        let cell = super.collectionView(
            collectionView,
            cellForItemAt: indexPath
        )
        let jsqCell = cell as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        let isOutgoing = (message.senderId == senderId)
        jsqCell.textView.textColor = (isOutgoing) ? .white : .black
        return jsqCell
    }
}
