//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Jeff Chiu on 12/20/2015.
//  Copyright (c) 2015 Jeff Chiu. All rights reserved.
//

//import "OnboardingViewController.h"
//import "OnboardingContentViewController.h"
import UIKit
import CoreData
@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    let userHasOnboardedKey = "user_has_onboarded"
    
    var window: UIWindow?
    var stats:Statistics! //The instance to keep the statistics

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        do {
            // Override point for customization after application launch.
            try fetchedResultsController.performFetch()
        } catch _ {
        } //Fetch the saved Statistics
        let objects = fetchedResultsController.fetchedObjects as! [Statistics]
        // Determine if the user has completed onboarding yet or not
        let userHasOnboardedAlready = NSUserDefaults.standardUserDefaults().boolForKey(userHasOnboardedKey);
        
        // If the user has already onboarded, setup the normal root view controller for the application
        // without animation like you normally would if you weren't doing any onboarding
        if userHasOnboardedAlready {
            self.setupNormalRootVC(false);
        }
            
            // Otherwise the user hasn't onboarded yet, so set the root view controller for the application to the
            // onboarding view controller generated and returned by this method.
        else {
            self.window!.rootViewController = self.generateOnboardingViewController()
        }
        self.window!.makeKeyAndVisible()
        
        if (objects).isEmpty{//If it is the first time tha app is running, Create a Statistics entry which will keep that stats in coredata in subsequent runs
            stats = Statistics(locations: 0, photos: 0, context: sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
        }else{
          stats = objects[0] //We should have only one Instance which keeps the statistics.
        }
        print("Total Locations Added: \(stats.locationsAdded), Total Photos Displayed: \(stats.photosDisplayed)") //Display the Stats in the Console only.
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }

    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Statistics")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "locationsAdded", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    func generateOnboardingViewController() -> OnboardingViewController {
        // Generate the first page...
        let firstPage: OnboardingContentViewController = OnboardingContentViewController(title: "What A Beautiful Photo", body: "This city background image is so beautiful", image: UIImage(named:
            "blue"), buttonText: "Enable Location Services") {
                print("Do something here...");
        }
        
        // Generate the second page...
        let secondPage: OnboardingContentViewController = OnboardingContentViewController(title: "I'm So Sorry", body: "I can't get over the nice blurry background photo.", image: UIImage(named:
            "red"), buttonText: "Connect With Facebook") {
                print("Do something else here...");
        }
        
        // Generate the third page, and when the user hits the button we want to handle that the onboarding
        // process has been completed.
        let thirdPage: OnboardingContentViewController = OnboardingContentViewController(title: "Seriously Though", body: "" , image: UIImage(named:
            "yellow"), buttonText: "Let's Get Started") {
                self.handleOnboardingCompletion()
        }
        
        let fourthPage: OnboardingContentViewController = OnboardingContentViewController(title: "Seriously Though", body: "Kudos to the photographer.", image: UIImage(named:
            "yellow"), buttonText: "Let's Get Started") {
                self.handleOnboardingCompletion()
        }
        
        // Create the onboarding controller with the pages and return it.

        
        let onboardingVC: OnboardingViewController = OnboardingViewController(backgroundImage: UIImage(named: "Yosemite National Park"), contents: [firstPage, secondPage, thirdPage, fourthPage])
        
//        onboardingVC.allowSkipping = YES
//        onboardingVC.skipHandler = ^{
//            [self handleOnboardingCompletion]
//        }
//        
        return onboardingVC
    }
    
    func handleOnboardingCompletion() {
        // Now that we are done onboarding, we can set in our NSUserDefaults that we've onboarded now, so in the
        // future when we launch the application we won't see the onboarding again.
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: userHasOnboardedKey)
        
        // Setup the normal root view controller of the application, and set that we want to do it animated so that
        // the transition looks nice from onboarding to normal app.
        setupNormalRootVC(true)
    }

    func setupNormalRootVC(animated : Bool) {
        // Here I'm just creating a generic view controller to represent the root of my application.
        let mainVC = UIViewController()
        mainVC.title = "Main Application"
        
        // If we want to animate it, animate the transition - in this case we're fading, but you can do it
        // however you want.
        if animated {
            UIView.transitionWithView(self.window!, duration: 0.5, options:.TransitionCrossDissolve, animations: { () -> Void in
                self.window!.rootViewController = mainVC
                }, completion:nil)
        }
            
            // Otherwise we just want to set the root view controller normally.
        else {
            self.window?.rootViewController = mainVC;
        }
    }
}

