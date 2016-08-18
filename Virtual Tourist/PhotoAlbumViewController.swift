//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Jeff Chiu on 12/20/2015.
//  Copyright (c) 2015 Jeff Chiu. All rights reserved.
//


import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController,UICollectionViewDelegate,NSFetchedResultsControllerDelegate {
    //MARK: Outlets
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var indicator: UIActivityIndicatorView! //The activity Indicator for the informationBox(not an alert view)
    @IBOutlet var map: MKMapView!
    @IBOutlet var imageInfoView: UIImageView!
    @IBOutlet var infoLabel: UILabel!
    //MARK: Variables:Other
    var prefetchedPhotos: [Photo]!//We put the Photo Objects in a variable to use in NSFetchedResultsControllerDelegate methods
    var newCollectionButton:UIBarButtonItem!
    var location:Location!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationController?.navigationBarHidden = false
        self.navigationController?.toolbarHidden = false
        
        do {
            //We invoke a performfetch for already fetched sets of image urls(the first stage) to be able to use it's delegate functionality
            try fetchedResultsController.performFetch()
        } catch _ {
        }
        fetchedResultsController.delegate = self
        
        imageInfoView?.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.70)
        imageInfoView.hidden = true
        infoLabel.hidden = true
        
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
        self.navigationController?.toolbarHidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.toolbarHidden = false
        
        setRegion() //Set the region on the top map based on the selected Location
        
        //"New Collection" Button and it's color
        newCollectionButton = UIBarButtonItem(title: "New Picture", style: .Plain, target: self, action: #selector(PhotoAlbumViewController.newCollection))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
        newCollectionButton.tintColor =  UIColor(red: (255/255.0), green: (0/255.0), blue: (132/255.0), alpha: 1.0)
        self.toolbarItems = [flexSpace,newCollectionButton,flexSpace]
    }
    


    // MARK: - Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    //Add the lazy fetchedResultsController property. Photos are already fetched(from flickr) and saved in Core data before this screen, but we fetch them again to use the NSFetchedResultsControllerDelegate methods
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.location);
        
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

    

    //
    // This is the most interesting method. Take particular note of way the that newIndexPath
    // parameter gets unwrapped and put into an array literal: [newIndexPath!]
    //
    
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Delete:
            self.collectionView.deleteItemsAtIndexPaths([indexPath!])
        case .Update:
            let cell = self.collectionView.cellForItemAtIndexPath(indexPath!) as! CollectionViewCell
            let photo = controller.objectAtIndexPath(indexPath!) as! Photo
            cell.photo.image = photo.image
        default:
            return
        }

    }
    
    //MARK: Collection View Related
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.prefetchedPhotos = self.fetchedResultsController.fetchedObjects as! [Photo]
        
        return prefetchedPhotos!.count
    }

    
    //Display the Cell
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! CollectionViewCell
        
        //If the photo image(imagepaths and titles are saved in Core Data) is saved using NSKeyedArchiver / NSKeyedUnarchiver we display it right away else we download it using its imagepath
        if let photo = NSKeyedUnarchiver.unarchiveObjectWithFile(Flickr.sharedInstance().imagePath((prefetchedPhotos![indexPath.row].imagePath as NSString).lastPathComponent)) as? UIImage {
            cell.indicator.stopAnimating()
            cell.photo.image = photo
        }else{
            cell.indicator.startAnimating()
            cell.photo.image = UIImage(named: "PlaceHolder") //Default placeholder
            Flickr.sharedInstance().downloadImageAndSetCell(prefetchedPhotos![indexPath.row].imagePath,cell: cell,completionHandler: { (success, errorString) in
                if success {
                    dispatch_async(dispatch_get_main_queue(), {
                        cell.indicator.stopAnimating()
                    })
                }else{
                    dispatch_async(dispatch_get_main_queue(), {
                        cell.indicator.stopAnimating()
                    })
                }
            })
        }
        return cell
    }
    
    //It is used for deleting the image from the collection view and the underlying core data context
    
    /// deleteObject
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath){
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        CoreDataStackManager.sharedInstance().deleteObject(photo)
    }
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat{
            return CGFloat(4.0)
    }
    
    //Distance between cells in a row
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return CGFloat(4.0)
    }
    
    //sets the border of the collection cell
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            return UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 10.0)
    }

    //MARK: Set the region
    //Set the region of the small map on top of the collection view using the location.
    func setRegion(){
        let span = MKCoordinateSpanMake(2, 2)
        let coordinates = CLLocationCoordinate2D(latitude: Double(location.latitude), longitude: Double(location.longitude))
        let region = MKCoordinateRegion(center: coordinates, span: span)
        let annotation = MKPointAnnotation() //We need to create a local variable to not mess up the global
        let tapPoint:CLLocationCoordinate2D = coordinates
        annotation.coordinate = tapPoint
        
        self.map.addAnnotation(annotation)
        self.map.setRegion(region, animated: true)
    }
    
    //MARK: New Collection Button
    //Generate a new collection of (12) images
    func newCollection() -> Bool { //I added a return value to exit when there is no connection

        let networkReachability = Reachability.reachabilityForInternetConnection()
        let networkStatus = networkReachability.currentReachabilityStatus()
        
        if(networkStatus.rawValue == NotReachable.rawValue){// Before searching fοr an additonal Photos in Flickr check if there is an available internet connection
            displayMessageBox("No Network Connection")
            return false
        }
        
        let applicationDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)//the appdelegate keeps a "Statistics" instance.
        informationBox("Connecting to Flickr",animate:true)
        newCollectionButton.enabled = false
        Flickr.sharedInstance().populateLocationPhotos(location) { (success,photosArray, errorString) in
            if success {
                dispatch_async(dispatch_get_main_queue(), {
                    
                    //Deleting the previous set of photos. It's inside dispatch_async because
                    //We avoid having a blank screen(deleted photos) while waiting a reply from flickr
                    for p in self.location.photos!{
                        CoreDataStackManager.sharedInstance().deleteObject(p)
                    }
                    
                    if let pd = photosArray{//We create the Photo instances from the photosArray and save them.
                        for p in pd{
                            let photo = Photo(dictionary: ["title":p[0],"imagePath":p[1]], context: self.sharedContext)
                            photo.location = self.location
                            applicationDelegate.stats.photosDisplayed += 1 //Save the number of displayed images for statistics.
                            CoreDataStackManager.sharedInstance().saveContext()
                        }
                    }
                    self.informationBox(nil,animate:false)
                    self.newCollectionButton.enabled = true
                    self.collectionView.reloadData()
                })
            } else {
                self.informationBox(nil,animate:false)
                self.displayMessageBox(errorString!) //Its appropriate at this point to display an Alert
                self.newCollectionButton.enabled = true
                print(errorString!)
            }
        }
        return true
    }
    
    //MARK: Other: alert view and a custom made information Box
    
    //A simple Alert view with an OK Button
    func displayMessageBox(message:String){
        let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    //Custom Made information Box using alpha value to create a black transparent background.
    func informationBox(msg:String?,let animate:Bool){
        if let _ = msg{
            if(animate){
                indicator.startAnimating()
            }
            print( "Testing Color TestingTestingTestingTesting")
            imageInfoView.hidden = false
            infoLabel.hidden = false
            //infoLabel.font =
            infoLabel.textColor = UIColor.whiteColor()
            infoLabel.text = msg
        }else{
            imageInfoView.hidden = true
            infoLabel.hidden = true
            infoLabel.textColor = UIColor.redColor()
            indicator.stopAnimating() //It doesn't hurt to stop animation in case it didn't start before
        }
    }
    

}

