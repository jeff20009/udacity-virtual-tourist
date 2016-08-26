//
//  Flickr.swift
//  Virtual Tourist
//  This class contains functions and helper methods to connect to Flickr API
//  Created by Jeff Chiu on 12/20/2015.
//  Copyright (c) 2015 Jeff Chiu. All rights reserved.
//


import Foundation
import CoreData
import UIKit

/// using Flickr API to set up the Session

class Flickr: NSObject{
    typealias CompletionHander = (result: AnyObject!, error: NSError?) -> Void
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    //MARK:Connecting to Flickr
    //It is used to fetch the list of images and the corresponding paths,titles... etc.
    func populateLocationPhotos(let location:Location,completionHandler: (success: Bool,helperArray: [[String]]?, errorString: String?) -> Void) {

            //In order to better randomization the first time we search for that location
            //We search the first(1) page. But in subsequent turns (new collection button pressed
            //,after we got the total pages value, We get results from a random page also.
            var page:Int = 1
            if let p = location.pages{
                page = Int(arc4random_uniform(UInt32(Double(p)))) + 1
            }

            let resource = Flickr.Constants.BASE_URL

            let parameters = [ //The parameters(arguments) for the method used: flickr.photos.search
                Flickr.MethodArguments.method: Flickr.Constants.METHOD_NAME,
                Flickr.MethodArguments.apiKey: Flickr.Constants.API_KEY,
                Flickr.MethodArguments.bbox: getBbox(location),
                Flickr.MethodArguments.safeSearch: Flickr.Constants.SAFE_SEARCH,
                Flickr.MethodArguments.extras: Flickr.Constants.EXTRAS ,
                Flickr.MethodArguments.format: Flickr.Constants.DATA_FORMAT,
                Flickr.MethodArguments.noJsonCallBack: Flickr.Constants.NO_JSON_CALLBACK,
                Flickr.MethodArguments.tags:"",
                    Flickr.MethodArguments.perPage:Flickr.Constants.MAXIMUM_PER_PAGE, //The maximum a bounding box query can return per page
                Flickr.MethodArguments.page:String(page)
            ]
        
            Flickr.sharedInstance().taskForResource(resource, parameters: parameters){ JSONResult, error  in
                if let error = error {
                    print(error)
                } else {
                    if let photosDictionary = JSONResult.valueForKey(Flickr.JsonResponse.photos) as? [String:AnyObject] {
                        if let photosArray = photosDictionary[Flickr.JsonResponse.photo] as? [[String: AnyObject]] {
                                
                                let totalPhotosVal = photosArray.count
                                if totalPhotosVal > 0 {
                                    var noPhotosToDisplay = totalPhotosVal
                                    if totalPhotosVal > Flickr.Constants.maxNumberOfImagesToDisplay{ //The maximum number of images that will be displayed by the collection view is maxNumberOfImagesToDisplay. I think this is a right assumption to put a cap considering the scope of the project.
                                        noPhotosToDisplay = Flickr.Constants.maxNumberOfImagesToDisplay
                                    }
                                    
                                if let totalPhotos = photosDictionary[Flickr.JsonResponse.pages] as? Int {
                                    dispatch_async(dispatch_get_main_queue()){
                                    location.pages = totalPhotos //Total number of pages for a location.If the result has more than one lines
                                    //The subsequent "new Album" searches in other pages alse. Because every flickr reply contains only one page (max 250 results) 
                                    }
                                }
                                    
                                var listPhotos:[Int] = [] //The list of photo indexes to display. It is used to avoid displaying the same images when the number of images are low.(arc4random_uniform function for low number of images ouputs the same number)
                                var helperArray = [[String]]() //It will consist of arrays of [title,imagePath] which then will be used to populate the core data entities
                                for _ in 0 ..< noPhotosToDisplay{
                                    
                                    //Sometimes if the total number of photos is low the random generator produces the same pictures
                                    //and with this while statement we ensure that all the displayed photos are different and for a low
                                    // max number of pictures(250) this while statement is not very costly.
                                    var randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                                    while (listPhotos.contains(randomPhotoIndex)){
                                        randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                                    }
                                    
                                    listPhotos.append(randomPhotoIndex)
                                    
                                    let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                                    let photoTitle = photoDictionary[Flickr.JsonResponse.title] as! String
                                    let imageUrlString = photoDictionary[Flickr.JsonResponse.imageType] as! String
                                    helperArray.append([photoTitle,imageUrlString])
                                }
                                completionHandler(success: true,helperArray:helperArray, errorString: nil)
                            } else {
                                completionHandler(success: false,helperArray:nil, errorString: "No available Photos Found")
                            }
                        } else {
                                completionHandler(success: false,helperArray:nil, errorString: "No available Photos Found")
                        }
                        
                    }
                }
            }
    }

    //It downloads the images from the already saved image paths to be in turn saved too in the CoreData
    func downloadImageAndSetCell(let imagePath:String,let cell:CollectionViewCell,completionHandler: (success: Bool, errorString: String?) -> Void){
        let imgURL = NSURL(string: imagePath)
        print("\(imagePath)")
        let request: NSURLRequest = NSURLRequest(URL: imgURL!)
        let mainQueue = NSOperationQueue.mainQueue()

        NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) -> Void in
        if error == nil {
            // Convert the downloaded data in to a UIImage object
            let image = UIImage(data: data!)
            let target =  self.imagePath((imagePath as NSString).lastPathComponent)
            
            NSKeyedArchiver.archiveRootObject(image!,toFile: target)
            
            cell.photo.image = image
            completionHandler(success: true, errorString: nil)
        }
        else {
            completionHandler(success: false, errorString: "Could not download image \(imagePath)")
        }
        })
    }

    
    
    
    //MARK:Saving Related
    //It returns the actual path in the iOS readable format
    func imagePath( selectedFilename:String) ->String{
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first!
        return url.URLByAppendingPathComponent(selectedFilename).path!
    }


    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    //MARK: create bounding box string.
    //return the bounding box: "bbox" flickr parameter
    func getBbox(let location:Location) -> String{
        let maxLong:NSNumber = (location.longitude as Double) + Flickr.Constants.boxSideLength
        let maxLat:NSNumber = (location.latitude as Double) + Flickr.Constants.boxSideLength
        let lat = "\(location.latitude)"
        let long = "\(location.longitude)"
        let a = long + "," + lat + "," + "\(maxLong)" + "," + "\(maxLat)"
        return a
    }

    
    // MARK: - All purpose task method for data
    
    func taskForResource(resource: String, parameters: [String : AnyObject], completionHandler: CompletionHander) -> NSURLSessionDataTask {
        
        let mutableParameters = parameters
        let mutableResource = resource + Flickr.escapedParameters(mutableParameters)
        
        let urlString = mutableResource
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                _ = Flickr.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: downloadError)
            } else {
                Flickr.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        
        task.resume()
        
        return task
    }

    
    
    
    // MARK: - Helpers
    
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if let parsedResult = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as? [String : AnyObject] {
            if let errorMessage = parsedResult["msg"] as? String {
                
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                
                return NSError(domain: "Flickr Error", code: 1, userInfo: userInfo)
            }
        }
        
        return error
    }

    
    // Parsing the JSON
    
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHander) {
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    // URL Encoding a dictionary into a parameter string
    
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            // make sure that it is a string value
            let stringValue = "\(value)"
            
            // Escape it
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            // Append it
            
            if let unwrappedEscapedValue = escapedValue {
                urlVars += [key + "=" + "\(unwrappedEscapedValue)"]
            } else {
                print("Warning: trouble excaping string \"\(stringValue)\"")
            }
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> Flickr {
        
        struct Singleton {
            static var sharedInstance = Flickr()
        }
        
        return Singleton.sharedInstance
    }
    
    // MARK: - Shared Date Formatter
    
    class var sharedDateFormatter: NSDateFormatter  {
        
        struct Singleton {
            static let dateFormatter = Singleton.generateDateFormatter()
            
            static func generateDateFormatter() -> NSDateFormatter {
                let formatter = NSDateFormatter()
                formatter.dateFormat = "yyyy-mm-dd"
                
                return formatter
            }
        }
        
        return Singleton.dateFormatter
    }
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }



}