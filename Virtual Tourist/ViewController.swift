//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by John Longenecker on 2/26/16.
//  Copyright © 2016 John Longenecker. All rights reserved.
//

import UIKit
import MapKit
import CoreData

private extension Selector {
    static let addPin = #selector(ViewController.addPin(_:))
}


class ViewController: UIViewController, MKMapViewDelegate {
    var longPress = false
    var pinArray = [LocationPin]()
    var priorPinLocation: MKAnnotation?
    var updatePin: LocationPin?
    var viewLoaded = false
    var pinTouched = false
    var photoCollectionViewController = PhotoCollectionViewController()
    var ann: MKAnnotation?
    var movePinEnabled = false
    
    

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var moveButtonOutlet: UIButton!
    
    
    @IBAction func movePinButtonPressed(sender: AnyObject) {
        movePin()
    }

    //This varibale holds the path for the saved Map.
    var filePathforVisibleMap: String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("visibleMap").path!
    }
    
    //Setting the context for core data.
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    
    //The Gesture Recognizer method is focued on setting up the long touch so that pins can be dragged. The other two methods are to reload pins if there were previously added pins.
    override func viewDidLoad() {
        setupGestureRecognizer()
        dispatch_async(dispatch_get_main_queue(), {
            self.pinArray = self.fetchAllPins()
            self.reloadPins()
        })
        
        moveButtonOutlet.hidden = true

    }

    
    //Cannot load a map position via coordiantes until after the view has loaded otherwise the map will move after loading (not ideal).
    override func viewDidAppear(animated: Bool) {
        let fileExists = checkIfFileExists()
        if fileExists {
            loadMapPosition()
        } else {
            print("Unable to load map position")
        }
        viewLoaded = true
        //map.deselectAnnotation(ann, animated: false)
    }
    

    
    func loadMapPosition() {
        if let setMapView = NSKeyedUnarchiver.unarchiveObjectWithFile(filePathforVisibleMap) {
            let mapRectTest = mapRectWork(setMapView as! mapViewSize)
            map.setVisibleMapRect(mapRectTest, animated: false)
            print("Savedmap \(map.visibleMapRect)")
            print("MapRectTest \(mapRectTest.origin.x), \(mapRectTest.origin.y) \(mapRectTest.size.width) \(mapRectTest.size.height)")
        }
    }
    
    //This checks if the map file exists. The method is not loading any other saved data.
    func checkIfFileExists()->Bool {
        if NSFileManager.defaultManager().fileExistsAtPath(filePathforVisibleMap) {
            print("File Saved")
            return true
        } else {
            print("File not Saved")
            return false
        }
    }
    
    func setupGestureRecognizer() {
        let uilgr = UILongPressGestureRecognizer(target: self, action: .addPin)
        uilgr.minimumPressDuration = 1.3
        map.addGestureRecognizer(uilgr)
        map.delegate = self
    }
    
    func fetchAllPins() -> [LocationPin] {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [LocationPin]
        } catch let error as NSError {
            print("Error in fetchAllPins \(error)")
            return [LocationPin]()
        }
    }
    
    //Reloading prior map loaction
    func mapRectWork(mapView: mapViewSize)->MKMapRect {
        return MKMapRect(origin: MKMapPoint(x: mapView.originx, y: mapView.originy), size: MKMapSize(width: mapView.sizeWidth, height: mapView.sizeHeight))
    }

    
    func addPin(gestureRecognizer:UILongPressGestureRecognizer){
        //longPress is necessary to ensure that multiple pins do not drop from a single press.
        if longPress == false {
            pinTouched = false
            moveButtonOutlet.hidden = false
            let flickrPage = 1
            let touchPoint = gestureRecognizer.locationInView(map)
            let newCoordinates = map.convertPoint(touchPoint, toCoordinateFromView: map)
            print("Add Pin \(newCoordinates.latitude)")
            
            
            let dictionary = [
                "latitude": newCoordinates.latitude as Double,
                "longitude": newCoordinates.longitude as Double
            ]
            
            let pinLocation = LocationPin(dictionary: dictionary, context: sharedContext)
            pinLocation.flickrPage = flickrPage
            CoreDataStackManager.sharedInstance().saveContext()

            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pinLocation.latitude), longitude: CLLocationDegrees(pinLocation.longitude))

            map.addAnnotation(annotation)
            longPress = true
            
        //Begins the Virtual Tourist client which takes care of searching FLickr for images and downloading them if they exist. Upon completion of the search, the reloadTestViewController is sent a message to reload and add the images. 
           VTClient.sharedInstance().downloadImagesFromFlicker(dictionary["latitude"]!, longitude: dictionary["longitude"]!, page: pinLocation.flickrPage, pin: pinLocation) {(success) in
                self.reloadPhotoViewController()
            }
            self.pinArray=self.fetchAllPins()
            
        }
        if gestureRecognizer.state == .Ended {
            longPress = false
        }
    }
    
    
    
    //placing pins on the map after retreiving from .DocumentCirector.
    func reloadPins() {
        
        for pin in pinArray {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
            map.addAnnotation(annotation)
            moveButtonOutlet.hidden = false
            print("Pin added")
        }
    }
    
    //Sets values of prior pin so that the pin can be updated with the new location.
    func assignPriorPinLocation(priorPinLocation: MKAnnotation) {
        for pin in pinArray {
            print("Pin Lattitude \(pin.latitude) Pin \(pin.longitude)")
            if pin.latitude == priorPinLocation.coordinate.latitude as Double && pin.longitude == priorPinLocation.coordinate.longitude {
                print("Prior Pin Lattitude \(pin.latitude) Prior pin \(pin.longitude)")
                updatePin = pin
                updatePin!.longitude = priorPinLocation.coordinate.longitude
                updatePin!.latitude = priorPinLocation.coordinate.latitude
                
            }
        }
    }
    
    
    //After pin movement update the pins location in Core Data and begin the photo download from flickr.
    func updatePinLocationInCoreData(pinLocation: LocationPin, newLocation: MKAnnotation) {
        let flickrPage = 1
        print("Old pin location latitude \(pinLocation.latitude) and longitude \(pinLocation.longitude)")
        pinLocation.latitude = newLocation.coordinate.latitude
        pinLocation.longitude = newLocation.coordinate.longitude
        let imageCache = ImageCache()
        if let photos = pinLocation.photos {
            for photo in photos {
                photo.pin = nil
                imageCache.deleteImage(photo.photoID)
                sharedContext.deleteObject(photo)
                //print("Pin Removed & Deleted")
            }
        }
        pinLocation.photoFinishedLoading = false
        pinLocation.flickrPage = flickrPage
        CoreDataStackManager.sharedInstance().saveContext()
        print("Context Saved")
        print("New pin location latitude \(pinLocation.latitude) and longitude \(pinLocation.longitude)")
        print("Pin after being saved \(pinLocation.photos)")
        VTClient.sharedInstance().downloadImagesFromFlicker(pinLocation.latitude, longitude: pinLocation.longitude, page: pinLocation.flickrPage, pin: pinLocation) {(success) in
            self.reloadPhotoViewController()
        }
    }
    
    //Sends a reload signal to the Collection View Controller if loaded so that it knows the photos have now been downloaded.
    func reloadPhotoViewController() {
        
        if pinTouched {
            print("ReloadTestViewController")
           // self.controller.reloadValues(pinTouched)
            photoCollectionViewController.reloadData()

        } else {
            print("PinTouched never set \(self.pinTouched)")
        }
    }
    
    
    // MARK: - mapView Delegates
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if viewLoaded {
            print("Region Did Change")
            let visibleMap = map.visibleMapRect
            print("\(visibleMap)")
        
            let testMapViewSize = mapViewSize(originx: visibleMap.origin.x, originy: visibleMap.origin.y, sizeHeight: visibleMap.size.height, sizeWidth: visibleMap.size.width)
            print("\(testMapViewSize.originx) \(testMapViewSize.originy) \(testMapViewSize.sizeWidth) \(testMapViewSize.sizeHeight)")
            let result = NSKeyedArchiver.archiveRootObject(testMapViewSize, toFile: filePathforVisibleMap).boolValue
            print("MapViewSaved \(result)")
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseID = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseID) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView!.animatesDrop = true
            pinView!.draggable = true
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if oldState == MKAnnotationViewDragState.Starting {
            priorPinLocation = view.annotation
            assignPriorPinLocation(priorPinLocation!)
            print("annotation began at: \(priorPinLocation!.coordinate.latitude),\(priorPinLocation!.coordinate.longitude)")
            
        }
        
        if newState == MKAnnotationViewDragState.Ending {
            let ann = view.annotation
            print("annotation dropped at: \(ann!.coordinate.latitude),\(ann!.coordinate.longitude)")
            mapView.deselectAnnotation(ann, animated: false)
            if let updatePin = updatePin, ann = ann {
                updatePinLocationInCoreData(updatePin, newLocation: ann)
            }
            
        }

    }
    
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        
        if movePinEnabled {

        } else {
            ann = view.annotation
            let coordinate = ann?.coordinate
            let pin = searchForCorrectPin(coordinate!)
            pinTouched = true
            print("Pin Touched")
            
            
            photoCollectionViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoCollectionViewController") as! PhotoCollectionViewController
            
            photoCollectionViewController.pin = pin
            let backItem = UIBarButtonItem()
            backItem.title = "Back"
            navigationItem.backBarButtonItem = backItem
            navigationController?.pushViewController(photoCollectionViewController, animated: true)
            mapView.deselectAnnotation(ann, animated: false)
        }

    }
    
    
    //searching for the correct pin so that the photoView can be loaded with the correct pin.
    func searchForCorrectPin(annotation: CLLocationCoordinate2D)->LocationPin?{
        for pin in pinArray {
            print("Pin Latitude \(pin.latitude) & Pin Longitude \(pin.longitude)")
            print("Annotation latitude \(annotation.latitude) Annotation logitude \(pin.longitude)")
            if pin.latitude == annotation.latitude as Double && pin.longitude == annotation.longitude as Double {
                print("Pin Found!")
                return pin
            } else {
                print("Pin Not Found")
            }
        }
        print("Returning Null Pin Array: \(pinArray)")
        return nil
    }
    

    //func to help control pin movement as selecting a pin causes complications with pin movement.
    func movePin() {
        if movePinEnabled {
            moveButtonOutlet.setTitle("Move Pin", forState: .Normal)
            movePinEnabled = false
        } else {
            movePinEnabled = true
            moveButtonOutlet.setTitle("Done", forState: .Normal)
        }
    }
}

