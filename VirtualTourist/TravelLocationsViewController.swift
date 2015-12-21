//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Jeff Chiu on 12/20/2015.
//  Copyright (c) 2015 Jeff Chiu. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    var alertVC : UIAlertController?
    
    struct MapKeys {
        static let Latitude = "LATITUDE"
        static let Longitude = "LONGITUDE"
        static let LatitudeDelta = "LATITUDE_DELTA"
        static let LongitudeDelta = "LONGITUDE_DELTA"
    }
    
    @IBOutlet weak var travelMap: MKMapView!
    var selectedAnnotation: LocationAnnotation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let gesture = UILongPressGestureRecognizer(target: self, action: Selector("handleGestureToAddLocation:"))
        gesture.minimumPressDuration = 1.5 //Seconds
        travelMap.addGestureRecognizer(gesture)
        
        do {
            try fetchedResultsController.performFetch()
        } catch _ {
        }
        
        fetchedResultsController.delegate = self
        
        if let locations = fetchedResultsController.fetchedObjects {
            for location in locations {
                self.addPinToMap(location as! Location)
            }
        }
        
        if NSUserDefaults.standardUserDefaults().doubleForKey(MapKeys.Latitude) != 0 {
            travelMap.setRegion(MKCoordinateRegionMake(CLLocationCoordinate2DMake(NSUserDefaults.standardUserDefaults().doubleForKey(MapKeys.Latitude), NSUserDefaults.standardUserDefaults().doubleForKey(MapKeys.Longitude)), MKCoordinateSpanMake(NSUserDefaults.standardUserDefaults().doubleForKey(MapKeys.LatitudeDelta), NSUserDefaults.standardUserDefaults().doubleForKey(MapKeys.LongitudeDelta))), animated: false)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
        self.travelMap.deselectAnnotation(selectedAnnotation, animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Location")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: NSManagedObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            let location = anObject as! Location
            
            switch type {
            case .Insert:
                //println("Insert item")
                addPinToMap(location)
            default:
                return
            }
    }
    
    func handleGestureToAddLocation(gestureRecogniser: UIGestureRecognizer) {
        if (gestureRecogniser.state != .Began) {
            return
        }
        let touchCoordinates = travelMap.convertPoint(gestureRecogniser.locationInView(travelMap), toCoordinateFromView: travelMap)
        
        let locationInformation: [String: AnyObject] = [
            Location.Keys.Name : "",
            Location.Keys.Latitude : touchCoordinates.latitude,
            Location.Keys.Longitude : touchCoordinates.longitude
        ]
        
        _ = Location(dictionary: locationInformation, context: self.sharedContext)
        
        do {
            try self.sharedContext.save()
        } catch _ {
        }
    }
    
    func addPinToMap(location: Location){
        let pinAnnotation = LocationAnnotation(annotationLocation: location)
        
        if location.photos.count == 0 {
            location.fetchForPhotos({ (success, errorString) -> Void in
                if success {
                    (self.travelMap.viewForAnnotation(pinAnnotation) as! MKPinAnnotationView).pinColor
                        = MKPinAnnotationColor.Red
                } else {
                    if errorString != nil {
                        self.alertVC = Helper.raiseInformationalAlert(inViewController: self, withTitle: "Error", message: errorString!, completionHandler: { (alertAction) -> Void in
                            self.alertVC!.dismissViewControllerAnimated(true, completion: nil)
                        })
                    }
                }
            })
        }
        
        travelMap.addAnnotation(pinAnnotation)
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //Save map location in User defaults
        NSUserDefaults.standardUserDefaults().setDouble(mapView.centerCoordinate.latitude, forKey: MapKeys.Latitude)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.centerCoordinate.longitude, forKey: MapKeys.Longitude)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.latitudeDelta, forKey: MapKeys.LatitudeDelta)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.longitudeDelta, forKey: MapKeys.LongitudeDelta)
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if newState == MKAnnotationViewDragState.Ending {
            (view as! MKPinAnnotationView).pinColor = .Purple
            view.resignFirstResponder()
            (view.annotation as! LocationAnnotation).location.fetchForPhotos({ (success, errorString) -> Void in
                if success {
                    let annot = view.annotation as! LocationAnnotation
                    if annot.location.photos.count > 0 {
                        dispatch_async(dispatch_get_main_queue()) {
                        (self.travelMap.viewForAnnotation(annot) as! MKPinAnnotationView).pinColor
                            = MKPinAnnotationColor.Red
                        }
                    }
                } else {
                    if errorString != nil {
                        self.alertVC = Helper.raiseInformationalAlert(inViewController: self, withTitle: "Error", message: errorString!, completionHandler: { (alertAction) -> Void in
                            self.alertVC!.dismissViewControllerAnimated(true, completion: nil)
                        })
                    }
                }
            })
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView! {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "locationPin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            if (annotation as! LocationAnnotation).location.photos.count == 0 {
                pinView!.pinColor = MKPinAnnotationColor.Purple
            } else {
                pinView!.pinColor = MKPinAnnotationColor.Red
            }
            //Prepare disclosure button that will be added to the pin
            let disclosureButton = UIButton(type: UIButtonType.DetailDisclosure)
            disclosureButton.addTarget(self, action: Selector("showPhotosForLocation:"), forControlEvents: UIControlEvents.TouchUpInside)
            
            pinView!.rightCalloutAccessoryView = disclosureButton
            
            pinView!.canShowCallout = true
            pinView!.draggable = true
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func showPhotosForLocation(sender: AnyObject) {
        var view = self.travelMap.viewForAnnotation(selectedAnnotation)
        
        if selectedAnnotation.location.isFetchingForPhotos == true {
            self.alertVC = Helper.raiseInformationalAlert(inViewController: self, withTitle: "Getting Ready...", message: "We are retrieving some cool photos of the location you just selected. It will be ready in a tick.", completionHandler: { (alertAction) -> Void in
                self.alertVC!.dismissViewControllerAnimated(true, completion: nil)
            })
        } else if (selectedAnnotation.location.photos.count == 0) {
            self.alertVC = Helper.raiseInformationalAlert(inViewController: self, withTitle: "No Images", message: "No images found for this location. Drag the pin to a new location.", completionHandler: { (alertAction) -> Void in
                self.alertVC!.dismissViewControllerAnimated(true, completion: nil)
            })
        } else {
            self.performSegueWithIdentifier("showLocationPhotos", sender: nil)
        }
        
        travelMap.deselectAnnotation(selectedAnnotation, animated: false)
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        selectedAnnotation = view.annotation as! LocationAnnotation
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        (segue.destinationViewController as! PhotoAlbumViewController).displayLocation = selectedAnnotation.location
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

