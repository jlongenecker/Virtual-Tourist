//
//  VTClient.swift
//  Virtual Tourist
//
//  Created by John Longenecker on 3/15/16.
//  Copyright © 2016 John Longenecker. All rights reserved.
//

import Foundation

//MARK: - VTClient: NSOBJECT

class VTClient: NSObject {
    //MARK: Properties
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
  
    //MARK: Search Flickr Photos
    
    func beginFlickrSearch(lattitude: Double, longitude: Double)->NSURLSessionDataTask {
        
        
        /* 1. Set the parameters */
        let methodArguements = [
            "method":VTClient.Constants.flickMethodName,
            "api_key" : VTClient.Constants.flickAPI,
            "bbox" : formatCorrdinatesForBoundingBox(lattitude, longitude: longitude),
            "safe_search": VTClient.ParameterKeys.safe_search,
            "extras" : VTClient.ParameterKeys.extras,
            "format" : VTClient.ParameterKeys.data_format,
            "nojsoncallback" : VTClient.ParameterKeys.no_json_callback
        ]
        
        let urlString = VTClient.Constants.flickURL + escapedParameters(methodArguements)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            /*GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request \(error)")
                return
            }
            
            /*GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode
            where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status Code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            let parsedResult = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! [String:AnyObject]
            
            print("ParsedResult: \(parsedResult)")
            
        }
        task.resume()
        
        return task
        
    }
    
    
    func formatCorrdinatesForBoundingBox(lattitude: Double, longitude: Double)-> String {
        return String(longitude - VTClient.Constants.BOUNDING_BOX_HALF_HEIGHT) + "," + String(lattitude - VTClient.Constants.BOUNDING_BOX_HALF_WIDTH) + "," + String(longitude + VTClient.Constants.BOUNDING_BOX_HALF_HEIGHT) + "," + String(lattitude + VTClient.Constants.BOUNDING_BOX_HALF_WIDTH)
        
    }
    
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
}