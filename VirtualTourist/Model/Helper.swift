//
//  Helper.swift
//  OnTheMap
//
//  Created by Jeff Chiu on 12/20/2015.
//  Copyright (c) 2015 Jeff Chiu. All rights reserved.
//

import Foundation
import UIKit

class Helper: NSObject {
    
    class func updateCurrentView(view : UIView, withActivityIndicator activityIndicator: UIActivityIndicatorView, andAnimate enable: Bool) {
        if enable {
            view.alpha = 0.6
            activityIndicator.startAnimating()
            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        } else {
            view.alpha = 1
            activityIndicator.stopAnimating()
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
            
        }
    }
    
    class func raiseInformationalAlert(inViewController viewController: UIViewController, withTitle title: String, message: String, completionHandler: ((UIAlertAction!) -> Void)) -> UIAlertController {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        //Add Actions to UIAlertController
        alertVC.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: completionHandler))
        
        viewController.presentViewController(alertVC, animated: true, completion: nil)
        
        return alertVC
    }
    
}