//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by John Longenecker on 2/26/16.
//  Copyright © 2016 John Longenecker. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {


    @IBOutlet weak var MapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

