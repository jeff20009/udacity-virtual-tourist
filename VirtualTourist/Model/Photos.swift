//
//  Photos.swift
//  VirtualTourist
//
//  Created by Jeff Chiu on 12/20/2015.
//  Copyright (c) 2015 Jeff Chiu. All rights reserved.
//

import Foundation
import CoreData

@objc(Photos)

class Photos: NSManagedObject {

    struct Keys {
        static let URLString = "urlString"
        static let Data = "data"
        static let Title = "title"
        static let Location = "location"
    }
    
    @NSManaged var urlString: String
    @NSManaged var data: NSData?
    @NSManaged var title: String
    @NSManaged var location: Location
    var isFetchingPhoto: Bool = false
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Photos", inManagedObjectContext: context)!
        
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        urlString = dictionary[Keys.URLString] as! String
        location = dictionary[Keys.Location] as! Location
        title = dictionary[Keys.Title] as! String
        
        //println("Photo created.")
    }
    
    func updatePhoto(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        urlString = dictionary[Keys.URLString] as! String
        location = dictionary[Keys.Location] as! Location
        title = dictionary[Keys.Title] as! String
        
        data = nil
        isFetchingPhoto = false
    }
    
    func fetchPhoto() {
        if data == nil && isFetchingPhoto == false {
            isFetchingPhoto = true
            NSURLConnection.sendAsynchronousRequest(NSURLRequest(URL: NSURL(string: urlString)!), queue: NSOperationQueue.mainQueue()) { (response, data, error) -> Void in
                if error == nil {
                    //println("Data received for \(self.title)")
                    self.data = data
                    CoreDataStackManager.sharedInstance().saveContext()
                } else {
                    self.isFetchingPhoto = false
                    self.data = nil
                    CoreDataStackManager.sharedInstance().saveContext()
                    //println("Error loading photo")
                }
            }
        }
    }
    
}
