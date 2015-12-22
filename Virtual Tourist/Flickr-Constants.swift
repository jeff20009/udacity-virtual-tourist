//
//  Flickr-Constants.swift
//  Virtual Tourist
//  Constants Used By the App
//  Created by Jeff Chiu on 12/20/2015.
//  Copyright (c) 2015 Jeff Chiu. All rights reserved.
//


import Foundation

extension Flickr{
    
    struct Constants { //Basic Constants
        // MARK: - URLs
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME = "flickr.photos.search"
        static let API_KEY = "237fe9755d90fb5b845fc6ab263062aa"
        static let GALLERY_ID = "5704-72157622566655097"
        static let EXTRAS = "url_m"
        static let DATA_FORMAT = "json"
        static let SAFE_SEARCH = "1"
        static let MAXIMUM_PER_PAGE = "250"
        static let NO_JSON_CALLBACK = "1"
        
        static let boxSideLength = 0.05 //The side in latitude,longtitude units of the square to search for photos
        static let maxNumberOfImagesToDisplay = 24 //
    }
    
    struct MethodArguments{ //Parameter names for Method
        static let method = "method"
        static let apiKey = "api_key"
        static let bbox = "bbox"
        static let safeSearch = "safe_search"
        static let extras = "extras"
        static let format = "format"
        static let noJsonCallBack = "nojsoncallback"
        static let perPage = "per_page"
        static let page = "page"
    }
    
    struct JsonResponse{ // Json Response tags
        static let photo = "photo"
        static let photos = "photos"
        static let pages = "pages"
        static let title = "title"
        static let imageType = "url_m"
    }
    
}