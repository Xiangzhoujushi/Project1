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
import SafariServices
import MapKit



class ViewController: JSQMessagesViewController, CLLocationManagerDelegate {
    
    
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
    var translateLang = ""
    var langToTranslator : [String: String] = ["spanish":"es", "french":"fr", "japanese":"ja", "korean":"ko"]
    var langToSpeech : [String: String] = ["spanish":"es-ES_BroadbandModel", "french":"fr-FR_BroadbandModel", "japanese":"ja-JP_BroadbandModel", "korean":"ko-KR_BroadbandModel" ]
    
    var popup = PopupDialog(title: "", message: "", image: UIImage(named: "TranslatorImage.png"))
    let locationManager = CLLocationManager()
    var currentCoordinate : CLLocationCoordinate2D?
    var restaurants = [CLLocationCoordinate2D]()
    var shopping = [String]()
    
    
//    discovery
    var environmentID = "6905356d-a4ef-4e0e-bd98-abebee8b0bc8"
    var collectionID = "217b915f-21ac-42ad-8df6-eb006869260f"
    var failWithError = ""
    ///"6905356d-a4ef-4e0e-bd98-abebee8b0bc8"
    var res = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInterface()
        setupSender()
        setupWatsonServices()
        setupTranslation()
        startConversation()
        
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        currentCoordinate = locationManager.location?.coordinate
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
    
    
    func  getRestaurants(coordinate: CLLocationCoordinate2D) -> (String, [CLLocationCoordinate2D]) {
        let yelpAPIClient = CDYelpAPIClient(apiKey: "JvDNq2ZH1KAEgrKhn1yoznmecpeT2ma-rXoBRkyWd3pXvS3yIIAo3Ne-g7ng51LFkAdWWsM3CeM3orEe-KzuulxofyTyyKPvyGJdxh9u1MrdcSIRVm68H0AkshGTWnYx")
        let semaphore = DispatchSemaphore(value: 0)
        var result = ""
        var result1 = [CLLocationCoordinate2D]()
        //let longitude = -83.015911
        //let latitude = 40.002323
        yelpAPIClient.searchBusinesses(byTerm: "Food",
                                       location: nil,
                                       latitude: coordinate.latitude,
                                       longitude:  coordinate.longitude,
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
                result += businesses[0].name! + ", \n"
                result += businesses[1].name! + ", \n"
                result += businesses[2].name!
                result1.append(CLLocationCoordinate2D(latitude: (businesses[0].coordinates?.latitude)!, longitude: businesses[1].coordinates!.longitude!))
                result1.append(CLLocationCoordinate2D(latitude: (businesses[1].coordinates?.latitude)!, longitude: businesses[1].coordinates!.longitude!))
                result1.append(CLLocationCoordinate2D(latitude: (businesses[2].coordinates?.latitude)!, longitude: businesses[1].coordinates!.longitude!))
                semaphore.signal()
            }
        }
        semaphore.wait()
        return (result, result1)
    }
    
    
    func getReview(_ num: Int) -> String{
        var result = ""
        let semaphore = DispatchSemaphore(value: 0)
        let business = allBusiness![num - 1]
        let yelpAPIClient = CDYelpAPIClient(apiKey: "JvDNq2ZH1KAEgrKhn1yoznmecpeT2ma-rXoBRkyWd3pXvS3yIIAo3Ne-g7ng51LFkAdWWsM3CeM3orEe-KzuulxofyTyyKPvyGJdxh9u1MrdcSIRVm68H0AkshGTWnYx")
        yelpAPIClient.fetchReviews(forBusinessId: business.id , locale: nil) { (response) in
            if let response = response, let reviews = response.reviews,reviews.count > 0 {
                result = reviews[0].text!
                let svc = SFSafariViewController(url: reviews[0].url!, entersReaderIfAvailable: true)
                self.present(svc, animated: true, completion: nil)
                semaphore.signal()
            }
        }
        semaphore.wait()
        return result
    }
    
    func getShopping(_ location: String)->(String, [String]){
        
        var result2 = [String]()
        /// String to search for within the documents.
        let query = location
        let failure = {(error:Error) in print(error)}
        ///var res = ""
        /// Find the max sentiment score for entities within the enriched text.
        let aggregation = ""
        ///"max(enriched_text.entities.sentiment.score)"
        var message = "Here are the shopping centers I found in " + location+":\n"
        /// Specify which portion of the document hierarchy to return.
        //let returnHierarchies = "results"
        let semaphore = DispatchSemaphore(value: 0)
        var num = 0
        let discovery = Discovery(
            username: Credentials.DiscoveryUsername,
            password: Credentials.DiscoveryPassword,
            version: "2018-03-05")
        discovery.queryDocumentsInCollection(
            withEnvironmentID: environmentID,
            withCollectionID: collectionID,
            withQuery: query,
            withAggregation: aggregation,
            ///return: returnHierarchies,
            failure: failure)
        {
            queryResponse in
            if let results = queryResponse.results {
                for result in results {
                    for text in  (result.enrichedTitle?.entities)!{
                        if(num<3){
                            
                            message += String(num+1)
                            message += ". "
                            //if(text.text)
                            message += text.text! + "\n"
                            result2.append(text.text!)
                            
                            num+=1
                        }else{
                            break
                        }
                    }
                    semaphore.signal()
                }
            }
        }
        semaphore.wait()
        return (message, result2)
    }
    
    /// Present a conversation reply and speak it to the user
    func presentResponse(_ response: MessageResponse) {
        currentCoordinate = locationManager.location?.coordinate
        var text = response.output.text.joined()
//        饭店
        if ((response.intents.count > 0) && (response.intents[0].intent == "locate_amenity")){
            
            let semaphore = DispatchSemaphore(value: 0)
            print(response.entities.count)
            if (response.entities.count>1){
                var coord:CLLocationCoordinate2D?
                Navigation().getCoordinate(addressString: response.entities[1].value){ coordinate, error in
                    coord = coordinate
                    print(coord)
                    print(coordinate)
                    semaphore.signal()
                }
                semaphore.wait()
                let (recommend, res) = getRestaurants(coordinate: coord!)
                text = String(recommend)
                restaurants = res
            }else{
                let (recommend, res) = getRestaurants(coordinate: currentCoordinate!)
                text = String(recommend)
                restaurants = res
            }
        }
//        反馈
        if ((response.intents.count > 0) && (response.intents[0].intent == "review")){
            text = "opening review"
            print(Int(response.entities[0].value)!)
            getReview(Int(response.entities[0].value)!)
        }
//        购物
        if ((response.intents.count > 0) && (response.intents[0].intent == "shopping")){
            let (shop_rec, shop_res) = getShopping(response.entities[1].value)
            text = String(shop_rec)
            shopping = shop_res
            print(shopping)
        }
//        天气
        if ((response.intents.count > 0) && (response.intents[0].intent == "weather")){
            if (response.entities.count == 0){
                text = WeatherPart().getWeather("Columbus")
            }else{
                text = WeatherPart().getWeather(response.entities[0].value)
            }
        }
//        导航
        if ((response.intents.count > 0) && (response.intents[0].intent == "navigation")){
            if (response.entities.count > 0){
                if(Int(response.entities[1].value) != nil && response.entities[0].value == "restaurant" ) {
                    text = "Start routing"
                    print(restaurants)
                    print(response.entities[0].value)
                    print(restaurants[Int(response.entities[1].value)!-1])
                    Navigation().openMap_cor(coordinate: restaurants[Int(response.entities[1].value)!-1])
                }else if (response.entities[0].value == "shopping mall"){
                    text = "Start routing"
                    print(shopping[Int(response.entities[1].value)!-1])
                    print(shopping[Int(response.entities[1].value)!-1])
                    Navigation().openMap(address: shopping[Int(response.entities[1].value)!-1])
                    
                }else{
                    text = "Start routing"
                    Navigation().openMap(address: response.entities[0].value)
                    }
            }
        }
//        翻译
        if ((response.intents.count > 0) && (response.intents[0].intent == "language"))
        {
            if(response.output.text[0] == "Okay! Start Translating..."){
                self.translateLang = response.entities[0].value
                popup = PopupDialog(title: "", message: "", image: UIImage(named: "TranslatorImage.png"))
                setupTranslation()
                self.present(popup, animated: true, completion: nil)
            }
        }
        
        
        //self.present(popup, animated: true, completion: nil)
        context = response.context // save context to continue conversation
        
        // synthesize and speak the response
        textToSpeech.synthesize(text: text, accept: "audio/wav", failure: failure) { audio in
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
        let translateRequest = TranslateRequest.init(text: [self.translate], source: "en", target: self.langToTranslator[self.translateLang]!)
        languageTranslator.translate(request: translateRequest, failure: failure) {
            translation in
            DispatchQueue.main.async {
                self.translate = translation.translations[0].translationOutput
                vc.messageText = self.translate
                self.textToSpeech.synthesize(text: self.translate, accept: "audio/wav", failure: self.failure) { audio in
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
        speechToText.recognizeMicrophone(settings: settings, model: self.langToSpeech[self.translateLang],failure: failure) { results in
            self.translate = results.bestTranscript
            vc.titleText = self.translate
            print(results.bestTranscript)
        }
    }
    
    @objc func otherStopTranscribing(){
        speechToText.stopRecognizeMicrophone()
        let vc = self.popup.viewController as! PopupDialogDefaultViewController
        let translateRequest = TranslateRequest.init(text: [self.translate], source: self.langToTranslator[self.translateLang]!, target: "en")
        languageTranslator.translate(request: translateRequest, failure: failure) {
            translation in
            DispatchQueue.main.async {
                self.translate = translation.translations[0].translationOutput
                vc.messageText = self.translate
                self.textToSpeech.synthesize(text: self.translate, accept: "audio/wav", failure: self.failure) { audio in
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

