//
//  CoreDataStackManager.swift
//  VirtualTourist
//
//  Created by Jeff Chiu on 12/20/2015.
//  Copyright (c) 2015 Jeff Chiu. All rights reserved.
//

import Foundation
import CoreData

/**
* The CoreDataStackManager contains the code that was previously living in the
* AppDelegate in Lesson 3. Apple puts the code in the AppDelegate in many of their
* Xcode templates. But they put it in a convenience class like this in sample code
* like the "Earthquakes" project.a
*
*/

private let SQLITE_FILE_NAME = "VirtualTourist.sqlite"

class CoreDataStackManager {
    
    
    // MARK: - Shared Instance
    class func sharedInstance() -> CoreDataStackManager {
        struct Static {
            static let instance = CoreDataStackManager()
        }
        
        return Static.instance
    }
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] 
        }()
    
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        let modelURL = NSBundle.mainBundle().URLForResource("VTModel", withExtension: "momd")
        let mom = NSManagedObjectModel(contentsOfURL: modelURL!)
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom!)
        
        let storeURL = self.applicationDocumentsDirectory.URLByAppendingPathComponent(SQLITE_FILE_NAME)
        
        var error: NSError? = nil
        
        var store: NSPersistentStore?
        do {
            store = try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
        } catch var error1 as NSError {
            error = error1
            store = nil
        } catch {
            fatalError()
        }
        if (store == nil) {
            print("Failed to load store")
        }
        
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = psc
        
        return managedObjectContext
        }()
    
    // MARK: - Core Data Saving support
    func saveContext () {
        
        if let context = self.managedObjectContext {
            
            var error: NSError? = nil
            
            if context.hasChanges {
                do {
                    try context.save()
                } catch let error1 as NSError {
                    error = error1
                    NSLog("Unresolved error \(error), \(error!.userInfo)")
                    abort()
                }
            }
        }
    }
}