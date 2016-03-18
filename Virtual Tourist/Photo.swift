//
//  Photo.swift
//  Virtual Tourist
//
//  Created by John Longenecker on 3/16/16.
//  Copyright © 2016 John Longenecker. All rights reserved.
//

import UIKit
import CoreData

class Photo : NSManagedObject {
    struct Keys {
        static let url_m = "url_m"
        static let url_o = "url_o"
        static let title = "title"
        static let id = "id"
    }

    @NSManaged var title: String
    @NSManaged var url_m: String
    @NSManaged var url_o: String?
    @NSManaged var photoID: String
    @NSManaged var pin: LocationPin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String:AnyObject], context: NSManagedObjectContext) {
        //Core Data
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        //Dictionary
        photoID = dictionary[Keys.id] as! String
        title = dictionary[Keys.title] as! String
        url_m = dictionary[Keys.url_m] as! String
        url_o = dictionary[Keys.url_o] as? String
    }
    
    
    //Need to add an image cache
    var image: UIImage? {
        get {
            let imageCache = ImageCache()
            return imageCache.retrieveImage(photoID)
        }
    }
    
}
