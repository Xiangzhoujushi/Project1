//
//  TableViewController.swift
//  Simple Chat
//
//  Created by Zhenyang Yu on 3/8/18.
//  Copyright © 2018 Glenn R. Fisher. All rights reserved.
//

import UIKit
import DiscoveryV1
import Foundation

class Cell:UITableViewCell{
    @IBOutlet weak var title: UILabel!
//    @IBOutlet weak var link: UITextField!
    @IBOutlet weak var passage: UITextView!
    @IBOutlet weak var link: UITextView!
    //    @IBOutlet weak var link: UITextField!
}

extension NSMutableAttributedString {
    
    public func setAsLink(textToFind:String, linkURL:String) -> Bool {
        
        let foundRange = self.mutableString.range(of: textToFind)
        if foundRange.location != NSNotFound {
            self.addAttribute(NSAttributedStringKey.link, value: linkURL, range: foundRange)
            return true
        }
        return false
    }
}

class TableViewController: UITableViewController {
    
    @IBOutlet var tableviews: UITableView!
    let username = Credentials.TravelGuideUsername
    let password = Credentials.TravelGuidePassword
    let version = "2018-1-26"
    let environmentID = "7bf82d68-26c2-49ae-9835-03b38377023e"
    let collectionID = "f71d3e53-2998-44c0-bbc6-00a97fa7f688"
    
    
    // use waston build in database
    let newsEnvironmentID = "system"
    let newsCollectionID = "news-en"
    
    // let
    // array of the data
    var dataArray : [String] = []
    var linkArray : [String] = []
    var textArray : [String] = []
    // declare the receive text
    var receiveText = ""
    
    // passage name register
    //    @IBOutlet var tableviews: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = 300
        //        self.tableView.rowHeight = 40.0
        // declare discovery services
        //        print ("error")
        queryDiscovery()
        //        print ("error")
        //       tableviews.reloadData()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func queryDiscovery(){
        let failure = { (error: Error) in print(error) }
        
        // receive text from the first view
        
        // return the top 5
        receiveText += " tour sites&count = 5"
        
        let query  = receiveText
        
        let discovery = Discovery(username:username,password:password,version:version)
        
        let aggregation = "max(enriched_text.entities.sentiment.score)"
        
        /// Specify which portion of the document hierarchy to return.
        //        let returnHierarchies = "enriched_text.entities.sentiment,enriched_text.entities.text"
        discovery.queryDocumentsInCollection(
            withEnvironmentID: newsEnvironmentID,
            withCollectionID: newsCollectionID,
            //            with:il 10,
            withQuery: query,
            withAggregation: aggregation,
            //            return: returnHierarchies,
            failure: failure)
        {
            queryResponse in
            if let results = queryResponse.results {
                // print out the results
                //                print(results)
//                var i = 0
                for result in results {
                    
                    if result.extractedURL != nil{
                        if let url = result.extractedURL{
                            self.linkArray.append(url)
                        }
                        else{
                            self.linkArray.append("No available Url")
                        }
                    }
                    else{
                        self.linkArray.append("No available Url")
                    }
                    
                    if result.text != nil{
                        if let text = result.text{
//                             print (text)
                            self.textArray.append(text)
                        }
                        else{
                            self.textArray.append("No available texts")
                        }
                    }
                    else{
                        self.textArray.append("No available texts")
                    }
                    //tht
                    if (result.title != nil){
                        if let txt = result.title{
                            self.dataArray.append(txt)
                            //                            print(self.dataArray[i])
                        }
                        else{
                            self.dataArray.append("No available title")
                        }
                        //                    print(result.text)
                    }
                    else{
                        self.dataArray.append("No available title")
                    }
                    
                 
                }
            }
            DispatchQueue.main.async {
                //                print("Finish Query")
                self.tableviews.reloadData()
            }
        }
        // reload the table views
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    //    override func numberOfSections(in tableView: UITableView) -> Int {
    //        // #warning Incomplete implementation, return the number of sections
    ////        print(data.count)
    //        return 1
    //    }
    
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return dataArray.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
            as? Cell else {
                fatalError("Cell Not Available")
        }
        ////         Configure the cell...
        //
        let txt = dataArray[indexPath.row]
        let link = linkArray[indexPath.row]
        let passage = textArray[indexPath.row]
        //        let label = dataArray[indexPath.row] + " source(" + linkArray[indexPath.row] + ")"
        //        let foundRange = self.mutableString.rangeOfString(txt)
        let linkString = NSMutableAttributedString(string : link)
        let linkWasSet = linkString.setAsLink(textToFind: link, linkURL: link)
        if linkWasSet {
            cell.link.attributedText = linkString
            cell.title.text = txt
            cell.passage.text = passage
        }else{
            // just assign it to be title
            cell.link.text = linkArray[indexPath.row]
            cell.title.text = txt
            cell.passage.text = passage
        }
//            cell.link.isEnabled = false
        
//            cell.passage.isEditable = false
        //        rcell.link.x/
        //        cell.detailTextLabel?.text = link
        return cell
    }
    
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

