//
//  TestViewController.swift
//  Virtual Tourist
//
//  Created by John Longenecker on 3/25/16.
//  Copyright © 2016 John Longenecker. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class TestViewController: UIViewController {

    @IBOutlet weak var testImageView: UIImageView!
    var pin: LocationPin!
    
    override func viewDidLoad() {
//        print("TestViewController Loading")
//        print("Pin Photos \(pin.photos)")
//        if pin.photos!.count != 0 {
//            print(" After Error Checkign Photos \(pin.photos)")
//            let photo = pin.photos![0]
//            testImageView.image = photo.image
//        }
        
        loadPhotosInImageView(pin)
    }
    
    func loadPhotosInImageView(pin: LocationPin) {
        if pin.photoFinishedLoading {
            if let photos = pin.photos {
                if photos.count != 0 {
                    let photo = photos[0]
                    testImageView.image = photo.image
                } else {
                    testImageView.image = UIImage(named: "PlaceHolderImage")
                    print("Pin contains no photos")
                }
            }
        } else {
            print("Photos still loading")
            testImageView.image = UIImage(named: "PlaceHolderImage")
        }
    }
    
    func reloadValues(newPin: LocationPin) {
        print("It is time to reload values")
//        print("\(newPin)")
//        print("Reload Pin Values \(newPin.photos![0].image)")
//        if let photo = newPin.photos![0].image {
//            print("Photo :\(photo)")
            dispatch_async(dispatch_get_main_queue(), {
                self.loadPhotosInImageView(newPin)
            })
//        }
    }

}
