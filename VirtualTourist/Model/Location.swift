//
//  Location.swift
//  VirtualTourist
//
//  Created by Jeff Chiu on 12/20/2015.
//  Copyright (c) 2015 Jeff Chiu. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Location)

class Location: NSManagedObject {
    
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let Name = "name"
        static let TotalNumberOfPages = "totalNumberOfPages"
        static let TotalNumberOfPhotos = "totalNumberOfPhotos"
        static let Photos = "photos"
    }
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var name: String?
    @NSManaged var totalNumberOfPages: NSNumber?
    @NSManaged var totalNumberOfPhotos: NSNumber?
    @NSManaged var photos: NSSet
    
    var isFetchingForPhotos: Bool = false
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Location", inManagedObjectContext: context)!
        
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        print(dictionary[Location.Keys.Latitude])
        
        print((dictionary[Location.Keys.Latitude] as! NSNumber).doubleValue)
        
        self.latitude = (dictionary[Location.Keys.Latitude] as! NSNumber).doubleValue
        self.longitude = (dictionary[Location.Keys.Longitude] as! NSNumber).doubleValue
        self.name = "\(self.latitude), \(self.longitude)"
        
        updateLocationName()
    }
    
    func updateLocationName() {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: self.latitude, longitude: self.longitude), completionHandler: { (placemarks, error) in
            if error != nil {
                print("Fail to reverse geocode location")
                self.name = "\(self.latitude), \(self.longitude)"
            } else if(placemarks!.count > 0) {
                let placemark = placemarks![0] as! CLPlacemark
                if placemark.subLocality != nil {
                    self.name = placemark.subLocality
                } else if placemark.locality != nil {
                    self.name = placemark.locality
                } else if(placemark.country != nil) {
                    self.name = placemark.country
                } else if (placemark.addressDictionary!["Name"] != nil) {
                    self.name = placemark.addressDictionar!;y["Name"] as? String
                }
            }
        })
    }
    
    func fetchForPhotos(completionHandler: (success: Bool, errorString: String?) -> Void) {
        if isFetchingForPhotos == true {
            completionHandler(success: false, errorString: nil)
            return
        }
        
        isFetchingForPhotos = true
        
        FlickrClient.sharedInstance().getImagesFromFlickrForLocation(self, withRandomPage: self.photos.count > 0 ? true : false) { (result, error) -> Void in
            self.isFetchingForPhotos = false
            if error != nil {
                completionHandler(success: false, errorString: "Error getting images from Flickr.")
                return
            }
            
            if let photosDictionary = result.valueForKey("photos") as? [String:AnyObject] {
                
                let totalPhotos = Int((photosDictionary["total"] as? String)!)
                
                self.totalNumberOfPhotos = totalPhotos!
                
                if totalPhotos < self.photos.allObjects.count {
                    for index in 1...(self.photos.allObjects.count - totalPhotos!) {
                    CoreDataStackManager.sharedInstance().managedObjectContext!.deleteObject(self.photos.allObjects[index - 1] as! NSManagedObject)
                    }
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                
                if totalPhotos == 0 {
                        completionHandler(success: true, errorString: nil)
                        return
                }
                
                if self.totalNumberOfPages == 0 {
                    if let totalPages = photosDictionary["pages"] as? Int {
                        
                        /* Flickr API - will only return up the 4000 images (100 per page * 40 page max) */
                        let pageLimit = min(totalPages, 40)
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit) + 1))
                        
                        self.totalNumberOfPages = pageLimit
                        CoreDataStackManager.sharedInstance().saveContext()
                    } else {
                        completionHandler(success: false, errorString: "Cant find key 'pages' in \(photosDictionary)")
                        return
                    }
                }
                
                if let photosArray = photosDictionary["photo"] as? [[String:AnyObject]] {
                    
                    var tempPhotos = [Photos]()
                    var allCurrentPhotos = self.photos.allObjects as! [Photos]
                    dispatch_async(dispatch_get_main_queue()) {
                        //Handle extra photo objects that might be under location
                        
                        for index in 1...min(photosArray.count, MAX_NUMBER_OF_PHOTOS) {
                            //println(index)
                            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                            let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                            
                            let photoTitle = photoDictionary["title"] as? String
                            let imageUrlString = photoDictionary["url_m"] as? String
                            
                            let photoInformation: [String: AnyObject] = [
                                Photos.Keys.Title : photoTitle!,
                                Photos.Keys.URLString : imageUrlString!,
                                Photos.Keys.Location : self
                            ]
                            
                            //Verify if a photo exists
                            if self.photos.count >= index {
                                //Update existing photo
                                
                                let currentPhoto = allCurrentPhotos[index-1]
                                currentPhoto.updatePhoto(photoInformation, context: CoreDataStackManager.sharedInstance().managedObjectContext!)
                                tempPhotos.append(currentPhoto)
                            }
                            else {
                                //Create new photo
                                tempPhotos.append(Photos(dictionary:photoInformation, context: CoreDataStackManager.sharedInstance().managedObjectContext!))
                            }
                        }
                        for photo in  tempPhotos {
                            photo.fetchPhoto()
                        }
                        
                        CoreDataStackManager.sharedInstance().saveContext()
                        
                        completionHandler(success: true, errorString:nil)
                    }
                } else {
                    completionHandler(success: false, errorString: "No photos found for location: \(self.name).")
                }
                
            } else {
                completionHandler(success: false, errorString: "Cant find key 'photos' in \(result)")
            }
        }
    }
}