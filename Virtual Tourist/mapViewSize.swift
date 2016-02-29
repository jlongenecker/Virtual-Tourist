//
//  mapViewSize.swift
//  Virtual Tourist
//
//  Created by John Longenecker on 2/29/16.
//  Copyright © 2016 John Longenecker. All rights reserved.
//

import Foundation

class mapViewSize: NSObject, NSCoding {
    
    
    struct Keys {
        static let originx = "originx"
        static let originy = "originy"
        static let sizeHeight = "sizeHeight"
        static let sizeWidth = "sizeWidth"
    }
    
    var originx: Double
    var originy: Double
    var sizeHeight: Double
    var sizeWidth: Double
    
    init(originx: Double, originy: Double, sizeHeight: Double, sizeWidth: Double) {
        self.originx = originx
        self.originy = originy
        self.sizeHeight = sizeHeight
        self.sizeWidth = sizeWidth
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(originx, forKey: Keys.originx)
        aCoder.encodeObject(originy, forKey: Keys.originy)
        aCoder.encodeObject(sizeHeight, forKey: Keys.sizeHeight)
        aCoder.encodeObject(sizeWidth, forKey: Keys.sizeWidth)
    }
    
    required init(coder aDecoder: NSCoder) {
        //super.init()
        
        originx = aDecoder.decodeObjectForKey(Keys.originx) as! Double
        originy = aDecoder.decodeObjectForKey(Keys.originy) as! Double
        sizeHeight = aDecoder.decodeObjectForKey(Keys.sizeHeight) as! Double
        sizeWidth = aDecoder.decodeObjectForKey(Keys.sizeWidth) as! Double
    }
    
 
}
