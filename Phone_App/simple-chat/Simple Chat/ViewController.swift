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

import CoreData
import UIKit
import UIKit
import JSQMessagesViewController
import PopupDialog
import OpenWeatherSwift
import PopupDialog
import AVFoundation
import ConversationV1
import SpeechToTextV1
import TextToSpeechV1
import DiscoveryV1
import LanguageTranslatorV2
import CDYelpFusionKit



class ViewController: JSQMessagesViewController {
    
    var messages = [JSQMessage]()
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    
    var conversation: Conversation!
    var speechToText: SpeechToText!
    var textToSpeech: TextToSpeech!
    var languageTranslator: LanguageTranslator!
    var discovery:Discovery!
    var audioPlayer: AVAudioPlayer?
    var workspace = Credentials.ConversationWorkspace
    var context: Context?
    var allBusiness: [CDYelpBusiness]?
    
    var speech = ""
    var translate = ""
    
    var popup = PopupDialog(title: "", message: "", image: UIImage(named: "TranslatorImage.png"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInterface()
        setupSender()
        setupWatsonServices()
        setupTranslation()
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
        languageTranslator = LanguageTranslator(
            username: Credentials.LanguageTranslatorUsername,
            password: Credentials.LanguageTranslatorPassword
        )
        discovery = Discovery(
            username: Credentials.DiscoveryUsername,
            password: Credentials.DiscoveryPassword,
            version: "2018-02-24")
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
    
    func getWeather(_ location: String) -> String{
        var result = ""
        //print(location)
        let client = OpenWeatherSwift(apiKey: "ed9049dc12e1698ee3b17de097abadaa", temperatureFormat: .Celsius)
        let semaphore = DispatchSemaphore(value: 0)
        if (location == "Columbus"){
            let myLocation = CLLocation(latitude: 39.96, longitude: -83)
            client.currentWeatherByCoordinates(coords: myLocation.coordinate){results in
                let weather = Weather2.init(data: results)
                result = "In " + location + " The Temperature is " + (String) (weather.temperature) + " celsius. The weather condition is " + (String)(weather.condition) + ". Visibility is " + (String)(weather.visibility) + " meters."
                semaphore.signal()
            }
        }else{
            client.currentWeatherByCity(name: location){results in
                let weather = Weather2.init(data: results)
                result = "In " + location + " The Temperature is " + (String) (weather.temperature) + " celsius. The weather condition is " + (String)(weather.condition) + ". Visibility is " + (String)(weather.visibility) + " meter."
                semaphore.signal()
            }
        }
        semaphore.wait()
        print (result)
        return result
    }
    
    
    func  getRestaurants() -> String {
        let yelpAPIClient = CDYelpAPIClient(apiKey: "JvDNq2ZH1KAEgrKhn1yoznmecpeT2ma-rXoBRkyWd3pXvS3yIIAo3Ne-g7ng51LFkAdWWsM3CeM3orEe-KzuulxofyTyyKPvyGJdxh9u1MrdcSIRVm68H0AkshGTWnYx")
        let semaphore = DispatchSemaphore(value: 0)
        var result = ""
        //let longitude = -83.015911
        //let latitude = 40.002323
        yelpAPIClient.searchBusinesses(byTerm: "Food",
                                       location: nil,
                                       latitude: 40.002323,
                                       longitude: -83.015911,
                                       radius: 10000,
                                       categories: [.activeLife, .food],
                                       locale: .english_unitedStates,
                                       limit: 5,
                                       offset: 0,
                                       sortBy: .rating,
                                       priceTiers: [.oneDollarSign, .twoDollarSigns],
                                       openNow: true,
                                       openAt: nil,
                                       attributes: nil)
        { (response) in
            if let response = response, let businesses = response.businesses, businesses.count > 0 {
                self.allBusiness = response.businesses
                result = "I have found some good restaurants: \n"
                result += businesses[0].name! + "\n"
                result += businesses[1].name! + "\n"
                result += businesses[2].name!
                semaphore.signal()
            }
        }
        semaphore.wait()
        return result
    }
    
    
    func getReview(_ num: Int) -> String{
        var result = ""
        let business = allBusiness![num - 1]
        let yelpAPIClient = CDYelpAPIClient(apiKey: "JvDNq2ZH1KAEgrKhn1yoznmecpeT2ma-rXoBRkyWd3pXvS3yIIAo3Ne-g7ng51LFkAdWWsM3CeM3orEe-KzuulxofyTyyKPvyGJdxh9u1MrdcSIRVm68H0AkshGTWnYx")
        yelpAPIClient.fetchReviews(forBusinessId: business.id , locale: nil) { (response) in
            if let response = response, let reviews = response.reviews,reviews.count > 0 {
                result = reviews[0].text!
            }
        }
        return result
    }

    /// Present a conversation reply and speak it to the user
    func presentResponse(_ response: MessageResponse) {
         if ((response.intents.count > 0) && (response.intents[0].intent == "locate_amenity")){
        print(response.entities[1].value)
    }
        if ((response.intents.count > 0) && (response.intents[0].intent == "review")){
            print(response.entities[0].value)
        }
        var text = response.output.text.joined()
        if ((response.intents.count > 0) && (response.intents[0].intent == "weather")){
            if (response.entities.count == 0){
                text = getWeather("Columbus")
            }else{
                text = getWeather(response.entities[0].value)
            }
        }
        
        
        
        if ((response.intents.count > 0) && (response.output.text[0] == "Okay! Start Translating..."))
        {
            popup = PopupDialog(title: "", message: "", image: UIImage(named: "TranslatorImage.png"))
            setupTranslation()
            self.present(popup, animated: true, completion: nil)
        }
        
        //self.present(popup, animated: true, completion: nil)
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

extension ViewController {
    
    func setupTranslation(){
        let buttonOne = DefaultButton(title: "ME", dismissOnTap: false) {
        }
        let buttonTwo = DefaultButton(title: "OTHER", dismissOnTap: false) {
        }
        popup.buttonAlignment = .horizontal
        
        buttonOne.addTarget(self, action: #selector(meStartTranscribing), for: .touchDown)
        buttonOne.addTarget(self, action: #selector(meStopTranscribing), for: .touchUpInside)
        buttonOne.addTarget(self, action: #selector(meStopTranscribing), for: .touchUpOutside)
        
        buttonTwo.addTarget(self, action: #selector(otherStartTranscribing), for: .touchDown)
        buttonTwo.addTarget(self, action: #selector(otherStopTranscribing), for: .touchUpInside)
        buttonTwo.addTarget(self, action: #selector(otherStopTranscribing), for: .touchUpOutside)
        
        // Add buttons to dialog
        popup.addButtons([buttonOne, buttonTwo])
    }
    
    @objc func meStartTranscribing(){
        audioPlayer?.stop()
        self.translate = ""
        let vc = self.popup.viewController as! PopupDialogDefaultViewController
        var settings = RecognitionSettings(contentType: .opus)
        settings.interimResults = true
        speechToText.recognizeMicrophone(settings: settings, failure: failure) { results in
            self.translate = results.bestTranscript
            vc.titleText = self.translate
            print(results.bestTranscript)
        }
    }
    
    @objc func meStopTranscribing(){
        speechToText.stopRecognizeMicrophone()
        let vc = self.popup.viewController as! PopupDialogDefaultViewController
        languageTranslator.translate(self.translate, from: "en", to: "es", failure: failure) {
            translation in
            DispatchQueue.main.async {
                self.translate = translation.translations[0].translation
                vc.messageText = self.translate
                self.textToSpeech.synthesize(self.translate, failure: self.failure) { audio in
                    self.audioPlayer = try! AVAudioPlayer(data: audio)
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer?.play()
                }
            }
        }
    }
    
    
    @objc func otherStartTranscribing(){
        audioPlayer?.stop()
        self.translate = ""
        let vc = self.popup.viewController as! PopupDialogDefaultViewController
        var settings = RecognitionSettings(contentType: .opus)
        settings.interimResults = true
        //speechToText.resetCustomization(withID: self.spanishId)
        speechToText.recognizeMicrophone(settings: settings, model: "es-ES_NarrowbandModel",failure: failure) { results in
            self.translate = results.bestTranscript
            vc.titleText = self.translate
            print(results.bestTranscript)
        }
    }
    
    @objc func otherStopTranscribing(){
        speechToText.stopRecognizeMicrophone()
        let vc = self.popup.viewController as! PopupDialogDefaultViewController
        languageTranslator.translate(self.translate, from: "es", to: "en", failure: failure) {
            translation in
            DispatchQueue.main.async {
                self.translate = translation.translations[0].translation
                vc.messageText = self.translate
                self.textToSpeech.synthesize(self.translate, failure: self.failure) { audio in
                    self.audioPlayer = try! AVAudioPlayer(data: audio)
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer?.play()
                }
            }
        }
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

