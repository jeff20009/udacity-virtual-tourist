//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Jeff Chiu on 12/20/2015.
//  Copyright (c) 2015 Jeff Chiu. All rights reserved.
//

import UIKit
import MapKit
import CoreData

let MAX_NUMBER_OF_PHOTOS = 12

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    var displayLocation : Location!
    var photoActions : UIAlertController!
    var selectedIndex: NSIndexPath?
    
    var alertVC : UIAlertController?
    
    var totalItems = 0
    
    @IBOutlet weak var photosCollectionView: UICollectionView!
    @IBOutlet weak var locationMap: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    var imagesFullyLoaded : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup UI
        self.navigationItem.title = displayLocation.name
        newCollectionButton.enabled = false
        
        setMapLocation()
        
        
        if displayLocation.photos.count == 0 {
            displayLocation.fetchForPhotos({ (success, errorString) -> Void in
                    if success {
                        print("Success fetching for photos.")
                    } else {
                        if errorString != nil {
                            self.alertVC = Helper.raiseInformationalAlert(inViewController: self, withTitle: "Error", message: errorString!, completionHandler: { (alertAction) -> Void in
                                self.alertVC!.dismissViewControllerAnimated(true, completion: nil)
                            })
                        }
                }
            })
        }
        
        do {
            //Location elements
            try fetchedResultsController.performFetch()
        } catch _ {
        }
        fetchedResultsController.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController.delegate = nil
    }
    
    func setMapLocation () {
        let locationCoordinate = CLLocationCoordinate2DMake(displayLocation.latitude, displayLocation.longitude)
        
        let enteredLocationAnnotation = MKPointAnnotation()
        enteredLocationAnnotation.coordinate = locationCoordinate
        
        self.locationMap.addAnnotation(enteredLocationAnnotation)
        
        //Update Map Region
        self.locationMap.centerCoordinate = locationCoordinate
        
        let miles = 30.0;
        let scalingFactor = abs((cos(2 * M_PI * locationCoordinate.latitude / 360.0) ))
        
        let span = MKCoordinateSpan(latitudeDelta: miles/69.0, longitudeDelta: miles/(scalingFactor*69.0))
        
        let region = MKCoordinateRegion(center: locationCoordinate, span: span)
        
        self.locationMap.setRegion(region, animated: true)
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photos")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.displayLocation);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections!.count
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //println("Fetched NumberOfObjects: \(self.fetchedResultsController.sections![section].numberOfObjects)")
        return self.fetchedResultsController.sections![section].numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let reuseIdentifier = "photoViewCell"
        
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photos
        
        let cell: PhotoCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        dispatch_async(dispatch_get_main_queue()) {
            if(photo.data == nil) {
                cell.activityView?.startAnimating()
                photo.fetchPhoto()
            } else {
                cell.imageView?.image = UIImage(data: photo.data!)
                self.trackNewCollectionButtonFunctionality()
            }
        }
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
            selectedIndex = indexPath
        
            photoActions = UIAlertController(title: "Remove", message: "Remove Photo?", preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            photoActions.addAction(UIAlertAction(title: "Remove", style: UIAlertActionStyle.Destructive, handler: removePhotoActionHandler))
            
            photoActions.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            
            self.presentViewController(photoActions, animated: true, completion: nil)
        
    }
    
    // MARK: - Fetched Results Controller Delegate
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType) {
            dispatch_async(dispatch_get_main_queue()) {
                switch type {
                case .Insert:
                    self.photosCollectionView.insertSections(NSIndexSet(index: sectionIndex))
                case .Delete:
                    self.photosCollectionView.deleteSections(NSIndexSet(index: sectionIndex))
                default:
                    return
                }
            }
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: NSManagedObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
                switch type {
                case .Insert:
                    //println("Insert item")
                    self.photosCollectionView.insertItemsAtIndexPaths([newIndexPath!])
                case .Delete:
                    //println("Delete item")
                    self.photosCollectionView.deleteItemsAtIndexPaths([indexPath!])
                case .Update:
                    //println("Update item")
                    let cell = self.photosCollectionView.cellForItemAtIndexPath(indexPath!) as! PhotoCollectionViewCell
                    let photo = controller.objectAtIndexPath(indexPath!) as! Photos
                    self.configureCell(cell, withPhoto: photo)
                default:
                    return
                }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.photosCollectionView.endEditing(true)
    }
    
    func removePhotoActionHandler(sender: UIAlertAction!) -> Void{
            self.sharedContext.deleteObject(self.fetchedResultsController.objectAtIndexPath(selectedIndex!) as! NSManagedObject)
            CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func configureCell(cell: PhotoCollectionViewCell,withPhoto photo: Photos) {
        cell.imageView!.image = nil
        
        
        //Update Cell ImageView
        if photo.data != nil {
            cell.activityView?.stopAnimating()
            cell.imageView?.image = UIImage(data: photo.data!)
            self.trackNewCollectionButtonFunctionality()
        } else {
            cell.activityView?.startAnimating()
        }
    }
    
    func trackNewCollectionButtonFunctionality() {
        self.imagesFullyLoaded += 1
        if self.imagesFullyLoaded == self.fetchedResultsController.sections![0].numberOfObjects {
            self.newCollectionButton.enabled = true
        }
    }
    
    @IBAction func retrieveNewCollectionOfPhotos(sender: AnyObject) {
        
        if displayLocation.totalNumberOfPhotos?.integerValue < MAX_NUMBER_OF_PHOTOS {
            self.alertVC = Helper.raiseInformationalAlert(inViewController: self, withTitle: "Error", message: "All available photos for this location have been retrieved.", completionHandler: { (alertAction) -> Void in
                self.alertVC!.dismissViewControllerAnimated(true, completion: nil)
            })
            return
        }
        
        //Reset settings of New Collection button
        self.imagesFullyLoaded = 0
        self.newCollectionButton.enabled = false
        
        //Reset all photos in Collection View
        for index in 1...photosCollectionView.numberOfItemsInSection(0) {
            let cell = photosCollectionView.cellForItemAtIndexPath(NSIndexPath(forRow: index - 1, inSection: 0))! as! PhotoCollectionViewCell
            
            cell.imageView?.image = nil
            cell.activityView?.startAnimating()
        }
        
        //Insert missing photos to CollectionView
        if MAX_NUMBER_OF_PHOTOS > photosCollectionView.numberOfItemsInSection(0) {
            for index in 1...(MAX_NUMBER_OF_PHOTOS - photosCollectionView.numberOfItemsInSection(0)) {
                let photoInformation: [String: AnyObject] = [
                    Photos.Keys.Title : "",
                    Photos.Keys.URLString : "",
                    Photos.Keys.Location : self.displayLocation
                ]
                
                Photos(dictionary: photoInformation, context: self.sharedContext)
                CoreDataStackManager.sharedInstance().saveContext()
            }
        }
        
        displayLocation.fetchForPhotos { (success, errorString) -> Void in
            if success {
                print("Successfully fetch for Photos")
            } else {
                if errorString != nil {
                    self.alertVC = Helper.raiseInformationalAlert(inViewController: self, withTitle: "Error", message: errorString!, completionHandler: { (alertAction) -> Void in
                        self.alertVC!.dismissViewControllerAnimated(true, completion: nil)
                    })
                }
            }
        }
    }
    
    
    func dismissAlertVC(alertAction: UIAlertAction) -> Void {
        self.alertVC!.dismissViewControllerAnimated(true, completion: nil)
    }
}