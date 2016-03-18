//
//  VTClient.swift
//  Virtual Tourist
//
//  Created by John Longenecker on 3/15/16.
//  Copyright © 2016 John Longenecker. All rights reserved.
//

import Foundation
import CoreData

//MARK: - VTClient: NSOBJECT

class VTClient: NSObject {
    //MARK: Properties
    var photosArray = [Photo]()
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()

    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
  
    //MARK: Search Flickr Photos
    
    func beginFlickrSearch(lattitude: Double, longitude: Double, page: Int?, completionHandler:(success: Bool, parsedResults: AnyObject?, error: NSError?)->Void)->NSURLSessionDataTask {
        let firstPage = "1"
        var methodArguements = [String:AnyObject]()
        if let page = page {
            /* 1. Set the parameters */
            methodArguements = [
                "method":VTClient.Constants.flickMethodName,
                "api_key" : VTClient.Constants.flickAPI,
                "bbox" : formatCorrdinatesForBoundingBox(lattitude, longitude: longitude),
                "safe_search": VTClient.ParameterKeys.safe_search,
                "extras" : VTClient.ParameterKeys.extras,
                "format" : VTClient.ParameterKeys.data_format,
                "nojsoncallback" : VTClient.ParameterKeys.no_json_callback,
                "per_page" : VTClient.ParameterKeys.per_page,
                "page": String(page)
            ]
        } else {
            
            methodArguements = [
                "method":VTClient.Constants.flickMethodName,
                "api_key" : VTClient.Constants.flickAPI,
                "bbox" : formatCorrdinatesForBoundingBox(lattitude, longitude: longitude),
                "safe_search": VTClient.ParameterKeys.safe_search,
                "extras" : VTClient.ParameterKeys.extras,
                "format" : VTClient.ParameterKeys.data_format,
                "nojsoncallback" : VTClient.ParameterKeys.no_json_callback,
                "per_page" : VTClient.ParameterKeys.per_page,
                "page": firstPage
            ]
        }
        
        
        let urlString = VTClient.Constants.flickURL + escapedParameters(methodArguements)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            /*GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request \(error)")
                completionHandler(success: false, parsedResults: nil, error: error)
                return
            }
            
            /*GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode
            where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status Code: \(response.statusCode)!")
                    completionHandler(success: false, parsedResults: nil, error: error)
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)")
                    completionHandler(success: false, parsedResults: nil, error: error)
                } else {
                    print("Your request returned an invalid response!")
                    completionHandler(success: false, parsedResults: nil, error: error)
                }
                return
            }
            
            guard let data = data else {
                print("No data was returned by the request!")
                completionHandler(success: false, parsedResults: nil, error: error)
                return
            }
            
            VTClient.parseJSON(data) {(success, results, error) in
                completionHandler(success: success, parsedResults: results, error: error)
            }
            
        }
        task.resume()
        
        return task
        
    }    
    
    
    
    //MARK: Helper Methods
    
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
    
    class func sharedInstance() -> VTClient {
        struct Singleton {
            static var sharedInstance = VTClient()
        }
        return Singleton.sharedInstance
    }
    
}