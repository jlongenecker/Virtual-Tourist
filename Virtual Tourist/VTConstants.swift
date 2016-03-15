//
//  VTConstants.swift
//  Virtual Tourist
//
//  Created by John Longenecker on 3/15/16.
//  Copyright © 2016 John Longenecker. All rights reserved.
//

import Foundation

extension VTClient {
    struct Constants {
        //MARK: URLs
        static let flickURL = "https://api.flickr.com/services/rest"
        static let flickAPI = "867585a7aa3cfc8f4ea35a4dffd7fe20"
        static let flickMethodName = "flickr.photos.search"
        static let BOUNDING_BOX_HALF_WIDTH = 0.01
        static let BOUNDING_BOX_HALF_HEIGHT = 0.01
    }
    
    struct ParameterKeys {
        static let safe_search = "1"
        static let extras = "url_m"
        static let data_format = "json"
        static let no_json_callback = "1"
    }
    
    struct JSONResponseKeys {
        //MARK: General JSON response keys
    }
}