//
//  LocalUser+CoreDataProperties.swift
//  
//
//  Created by Peiyuan Tang on 2018/4/3.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension LocalUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalUser> {
        return NSFetchRequest<LocalUser>(entityName: "LocalUser")
    }

    @NSManaged public var date: Date?
    @NSManaged public var email: String?
    @NSManaged public var name: String?
    @NSManaged public var password: String?
    @NSManaged public var userID: Int64

}
