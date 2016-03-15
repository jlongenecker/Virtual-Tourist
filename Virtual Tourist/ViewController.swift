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

class ViewController: UIViewController, MKMapViewDelegate {
    var longPress = false
    var pinArray = [LocationPin]()
    var priorPinLocation: MKAnnotation?
    var updatePin: LocationPin?
    var viewLoaded = false

    @IBOutlet weak var map: MKMapView!
    
    var filePathforVisibleMap: String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("visibleMap").path!
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupGestureRecognizer()
        dispatch_async(dispatch_get_main_queue(), {
            self.pinArray = self.fetchAllPins()
            self.reloadPins()
        })
        
    }
    
    override func viewDidAppear(animated: Bool) {
        let fileExists = checkIfFileExists()
        if fileExists {
            loadMapPosition()
        } else {
            print("Unable to load map position")
        }
        viewLoaded = true
    }
    
    func loadMapPosition() {
        if let setMapView = NSKeyedUnarchiver.unarchiveObjectWithFile(filePathforVisibleMap) {
            let mapRectTest = mapRectWork(setMapView as! mapViewSize)
            map.setVisibleMapRect(mapRectTest, animated: false)
            print("Savedmap \(map.visibleMapRect)")
            print("MapRectTest \(mapRectTest.origin.x), \(mapRectTest.origin.y) \(mapRectTest.size.width) \(mapRectTest.size.height)")
        }
    }
    
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
        let uilgr = UILongPressGestureRecognizer(target: self, action: "addPin:")
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
    
    
    func mapRectWork(mapView: mapViewSize)->MKMapRect {
        return MKMapRect(origin: MKMapPoint(x: mapView.originx, y: mapView.originy), size: MKMapSize(width: mapView.sizeWidth, height: mapView.sizeHeight))
    }

    
    func addPin(gestureRecognizer:UILongPressGestureRecognizer){
        //longPress is necessary to ensure that multiple pins do not drop from a single press.
        if longPress == false {
            let touchPoint = gestureRecognizer.locationInView(map)
            let newCoordinates = map.convertPoint(touchPoint, toCoordinateFromView: map)
            print("\(newCoordinates.latitude)")
            
            
            let dictionary = [
                "latitude": newCoordinates.latitude as Double,
                "longitude": newCoordinates.longitude as Double
            ]
            
            let pinLocation = LocationPin(dictionary: dictionary, context: sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()

            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pinLocation.latitude), longitude: CLLocationDegrees(pinLocation.longitude))

            map.addAnnotation(annotation)
            longPress = true
            
            let flickerSearch = VTClient()
            
            flickerSearch.beginFlickrSearch(dictionary["latitude"]!, longitude: dictionary["longitude"]!)
            
        }
        if gestureRecognizer.state == .Ended {
            longPress = false
        }
    }
    
    
    func reloadPins() {
        for pin in pinArray {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
            map.addAnnotation(annotation)
        }
    }
    
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
    
    func updatePinLocationInCoreData(pinLocation: LocationPin, newLocation: MKAnnotation) {
        pinLocation.latitude = newLocation.coordinate.latitude
        pinLocation.longitude = newLocation.coordinate.longitude
        CoreDataStackManager.sharedInstance().saveContext()
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
            if let updatePin = updatePin, ann = ann {
                updatePinLocationInCoreData(updatePin, newLocation: ann)
            }
            
        }

    }
    

}

