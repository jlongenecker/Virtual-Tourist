//
//  ImageCache.swift
//  Virtual Tourist
//
//  Created by John Longenecker on 3/17/16.
//  Copyright © 2016 John Longenecker. All rights reserved.
//

import Foundation
import UIKit

class ImageCache {
    
//    var path: String
//    
//    required init(path:String) {
//        self.path = path
//        
//    }
    
    

    
    func downloadImage(path:String, url: String)->UIImage? {
        var filePath : String {
            let manager = NSFileManager.defaultManager()
            let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
            return url.URLByAppendingPathComponent(path).path!
        }
        
        let imgUrl = NSURL(string: url)
            
        let imgData = NSData(contentsOfURL: imgUrl!)
            
        let image = UIImage(data: imgData!)
            
        let saveResult = NSKeyedArchiver.archiveRootObject(image!, toFile: filePath).boolValue
        print("Save Result \(saveResult)")
        return image

    }
    
    
    func retrieveImage(path: String) -> UIImage? {
        var filePath : String {
            let manager = NSFileManager.defaultManager()
            let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
            return url.URLByAppendingPathComponent(path).path!
        }
        
        if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            print("We have a file")
            let image = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as! UIImage
            return image
        } else {
            print("No Image Found")
            return UIImage(named: "PlaceHolderImage")
        }
    }
    
    func deleteImage(path: String) {
        var filePath : String {
            let manager = NSFileManager.defaultManager()
            let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
            return url.URLByAppendingPathComponent(path).path!
        }
        
        let fileManager = NSFileManager()
        do {
            try fileManager.removeItemAtPath(filePath)
            print("File Deleted at \(filePath)")
        } catch {
            print("Unable to delete file at \(filePath)")
        }
        
        if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            print("File has not been deleted at \(filePath)")
        } else {
            print("File has been deleted at \(filePath)")
        }
    }

    
    
}