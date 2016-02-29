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
        // Do any additional setup after loading the view, typically from a nib.
        let uilgr = UILongPressGestureRecognizer(target: self, action: "addPin:")
        uilgr.minimumPressDuration = 1.3
        map.addGestureRecognizer(uilgr)
        map.delegate = self

        if NSFileManager.defaultManager().fileExistsAtPath(filePathforVisibleMap) {
            print("File Saved")
        } else {
            print("File not Saved")
        }
        
        if let setMapView = NSKeyedUnarchiver.unarchiveObjectWithFile(filePathforVisibleMap) {
            let mapRect = mapRectWork(setMapView as! mapViewSize)
            map.setVisibleMapRect(mapRect, animated: true)
        }
        pinArray = fetchAllPins()
        reloadPins()
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func addPin(gestureRecognizer:UILongPressGestureRecognizer){
        if longPress == false {
            print("Long Press")
            let touchPoint = gestureRecognizer.locationInView(map)
            let newCoordinates = map.convertPoint(touchPoint, toCoordinateFromView: map)
            print("\(newCoordinates.latitude)")
            let dictionary = [
                "latitude": newCoordinates.latitude as Double,
                "longitude": newCoordinates.longitude as Double
            ]
            let pinLocation = LocationPin(dictionary: dictionary, context: sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
            print("Pin Location \(pinLocation.longitude)")
            print("\(newCoordinates)")
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pinLocation.latitude), longitude: CLLocationDegrees(pinLocation.longitude))
            print("\(annotation.coordinate)")
            map.addAnnotation(annotation)
            longPress = true
            
        }
        if gestureRecognizer.state == .Ended {
            longPress = false
        }
    }
    
    func reloadPins() {
        for pin in pinArray {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
            print("\(annotation.coordinate)")
            map.addAnnotation(annotation)
        }
    }
    
    // MARK: - mapView Delegates
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let visibleMap = map.visibleMapRect
        
        let testMapViewSize = mapViewSize(originx: visibleMap.origin.x, originy: visibleMap.origin.y, sizeHeight: visibleMap.size.height, sizeWidth: visibleMap.size.width)
        let result = NSKeyedArchiver.archiveRootObject(testMapViewSize, toFile: filePathforVisibleMap).boolValue
        print(result)
        
        
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
        if newState == MKAnnotationViewDragState.Ending {
            let ann = view.annotation
            print("annotation dropped at: \(ann!.coordinate.latitude),\(ann!.coordinate.longitude)")
        }
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        //Required for updating pin location in pinArray
        print("\(view.annotation?.coordinate.latitude) \(view.annotation?.coordinate.longitude)")
    }

}

