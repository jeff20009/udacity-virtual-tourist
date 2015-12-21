//
//  UdacityConstants.swift
//  OnTheMap
//
//  Created by Antonio Maradiaga on 26/03/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

extension FlickrClient {

    // MARK: - Constants
    struct Constants {
        static let BaseURL : String = "https://api.flickr.com/services/rest/"
        static let APIKey : String = "60d79188f8d90a27d111b22a803d7ecf"
        static let Extras : String = "url_m"
        static let DataFormat : String = "json"
        static let NoJSONCallbank = "1"
        static let BoundingBoxHalfWidth = 1.0
        static let BoundingBoxHalfHeight = 1.0
    }
    
    struct Methods{
        static let Search: String = "flickr.photos.search"
    }

}