//
//  PhotoCollectionViewController.swift
//  Virtual Tourist
//
//  Created by John Longenecker on 3/26/16.
//  Copyright © 2016 John Longenecker. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import MapKit



private let reuseIdentifier = "PhotoCell"

class PhotoCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, MKMapViewDelegate {
    
    
    //set properties and UIButtons
    var selectedIndexes = [NSIndexPath]()
    
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var barButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!

    
    var cancelButton: UIBarButtonItem!
    
    var pin: LocationPin!
    
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
        } catch let error1 as NSError {
            error = error1
        }
        
        if let error = error {
            print("Error performing initial fetch: \(error)")
        }
        
        barButton.setTitle("Download New Collection", forState: .Normal)
        
        setRegion()
        addPin()
        
        noImages()


    }

    
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
//        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        
        let width = floor(((self.collectionView.frame.size.width)-0.05)/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }

    
    //MARK: - Configure Cell
    
    func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        print("Cell URL: \(photo.url_m)")
        cell.cellImageView.image = photo.image
        
        if let _ = selectedIndexes.indexOf(indexPath) {
            cell.cellImageView.alpha = 0.4
        } else {
            cell.cellImageView.alpha = 1.0
        }
    }
    
    // MARK: - UICollectionView
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        print("NumberOfSections method called")
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        print("number Of Cells: \(sectionInfo.numberOfObjects)")
        
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        
        configureCell(cell, atIndexPath: indexPath)
        
        
        
        return cell
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
            barButtonTitle()
        } else {
            selectedIndexes.append(indexPath)
            barButtonTitle()
        }
        
        configureCell(cell, atIndexPath: indexPath)
        
        
    }
    
    //MARK: - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "photoID", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        
        print("\(self.pin.latitude)")
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        
        print("\(fetchedResultsController.sections)")
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
        }()

    //MARK: - Fetched Results Controller Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
            
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete the photo from the array")
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item")
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item.")
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
            print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
        }, completion: nil)
        
        
    }
    

    
    
    @IBAction func barButtonPressed(sender: AnyObject) {
        if selectedIndexes.count > 0 {
            deletedSelectedPhotos()
            barButtonTitle()
        } else {
            deleteOldPhotos()
            addToCollection()
        }
        
    }
    
    

    func deletedSelectedPhotos() {
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            let imageCache = ImageCache()
            imageCache.deleteImage(photo.photoID)
            sharedContext.deleteObject(photo)
            CoreDataStackManager.sharedInstance().saveContext()

        }
        
        selectedIndexes = [NSIndexPath]()
    }
    

    //reloads data after it has been returned by the client.
    func reloadData() {
        print("Test Reload Data")
        dispatch_async(dispatch_get_main_queue(), {
            self.collectionView.reloadItemsAtIndexPaths(self.collectionView.indexPathsForVisibleItems())
            self.noImages()
        })
        
    }
    
    func barButtonTitle () {
        if selectedIndexes.count > 0 {
            barButton.setTitle("Remove From Collection", forState: .Normal)
        } else {
            barButton.setTitle("Download New Photos", forState: .Normal)
        }
    }
    
    
    //MARK: MapKit Delegate
    
    func setRegion() {
        let lanDelta = 0.075
        let longDelta = 0.075
        let span = MKCoordinateSpanMake(lanDelta, longDelta)
        let longitude = CLLocationDegrees(self.pin.longitude)
        let lattitude = CLLocationDegrees(self.pin.latitude)
        let coordinate2d = CLLocationCoordinate2D(latitude: lattitude, longitude: longitude)
        let region2 = MKCoordinateRegion(center: coordinate2d, span: span)
        mapView.setRegion(region2, animated: false)
        mapView.scrollEnabled = false
        mapView.zoomEnabled = false
        mapView.pitchEnabled = false
        mapView.rotateEnabled = false
        
        
    }
    
    //MARK: Map Annotations
    
    func addPin() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(self.pin.latitude), longitude: CLLocationDegrees(self.pin.longitude))
        mapView.addAnnotation(annotation)
    }
    
    //MARK: Helper functions
    
    func addToCollection() {
        let client = VTClient()
        pin.flickrPage += 1
        CoreDataStackManager.sharedInstance().saveContext()
        client.downloadImagesFromFlicker(self.pin.latitude, longitude: self.pin.longitude, page: pin.flickrPage, pin: self.pin) {(success) in
            self.reloadData()
        }
    }
    
    func deleteOldPhotos() {
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            let imageCache = ImageCache()
            imageCache.deleteImage(photo.photoID)
            sharedContext.deleteObject(photo)
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    func noImages() {
        if fetchedResultsController.fetchedObjects?.count < 1 {
            collectionView.hidden = true
        }
    }
}
