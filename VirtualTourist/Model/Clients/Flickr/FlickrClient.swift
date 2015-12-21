//
//  UdacityClient.swift
//  OnTheMap
//
//  Created by Antonio Maradiaga on 26/03/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class FlickrClient: NSObject{
    
    typealias CompletionHander = (result: AnyObject!, error: NSError?) -> Void
    
    /* Shared session */
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    func getImagesFromFlickrForLocation(location: Location, withRandomPage random : Bool, completionHandler: CompletionHander) -> NSURLSessionDataTask {
            
            var methodArguments = [
                "method": Methods.Search,
                "api_key": Constants.APIKey,
                "bbox": createBoundingBoxString(CLLocationCoordinate2D(latitude:location.latitude, longitude:location.longitude)),
                "extras": Constants.Extras,
                "format": Constants.DataFormat,
                "nojsoncallback": Constants.NoJSONCallbank
            ]
            
            let urlString = Constants.BaseURL + NetworkHelper.escapedParameters(methodArguments)
            let url = NSURL(string: urlString)!
            let request = NSURLRequest(URL: url)
        
            if random == true {
                let pageNumber = Int(arc4random_uniform(UInt32(((location.totalNumberOfPages != nil) ? location.totalNumberOfPages!.intValue : 40))))
                
                //println("Total Number of Pages -> \(location.totalNumberOfPages) | Random -> \(pageNumber)")
                methodArguments["page"] = String(pageNumber)
            }
            
            let task = session.dataTaskWithRequest(request) {data, response, downloadError in
                if let error = downloadError {
                    print("Could not complete the request \(error)")
                    completionHandler(result: nil, error: error)
                } else {
                    var parsingError: NSError? = nil
                    let parsedResult = (try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as! NSDictionary
                    
                    if parsingError == nil {
                        completionHandler(result: parsedResult, error: nil)
                    } else {
                        completionHandler(result: nil, error: parsingError)
                    }
                    
                }
            }
            
            task.resume()
                
            return task
    }
    
    func createBoundingBoxString(coordinates:
        CLLocationCoordinate2D) -> String {
            let latitude = coordinates.latitude
            let longitude = coordinates.longitude
            
            return "\(longitude - FlickrClient.Constants.BoundingBoxHalfWidth),\(latitude - FlickrClient.Constants.BoundingBoxHalfHeight),\(longitude + FlickrClient.Constants.BoundingBoxHalfWidth),\(latitude + FlickrClient.Constants.BoundingBoxHalfHeight)"
    }
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
}