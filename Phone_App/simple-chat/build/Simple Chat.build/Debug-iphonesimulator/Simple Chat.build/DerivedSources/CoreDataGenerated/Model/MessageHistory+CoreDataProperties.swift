//
//  MessageHistory+CoreDataProperties.swift
//  
//
//  Created by Peiyuan Tang on 2018/4/3.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension MessageHistory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MessageHistory> {
        return NSFetchRequest<MessageHistory>(entityName: "MessageHistory")
    }

    @NSManaged public var attribute: Int64
    @NSManaged public var date: Date?
    @NSManaged public var message: String?

}
