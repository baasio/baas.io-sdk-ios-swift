//
//  SimpleNetworkManager.swift
//  baas.io-sdk-ios-swift
//
//  Created by kimkkikki on 2014. 6. 9..
//  Copyright (c) 2014년 baas.io. All rights reserved.
//

import Foundation

class SimpleNetworkManager: NSObject {
    
    class func sharedInstance() -> SimpleNetworkManager! {
        struct Static {
            static var token : dispatch_once_t = 0
            static var instance : SimpleNetworkManager? = nil
        }
        
        dispatch_once(&Static.token) { Static.instance = SimpleNetworkManager() };
        return Static.instance!
    }

    func connectWithHTTPSync(path: String, method: String, params: NSDictionary, headerFields: NSDictionary, error: NSErrorPointer) -> String {
        var response:String?
        var isFinish:Bool = false
        var closureError:NSError?
        
        var operation:NSOperation = connectWithHTTP(path, method: method, params: params, headerFields: headerFields,
            success: {
                (result:String) in
                response = result
                isFinish = true
            }, failure: {
                (error:NSError) in
                closureError = error
                isFinish = true
            })!
        
        operation.waitUntilFinished()
        
        #if UNIT_TEST
            while(!isFinish) {
                NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow:0.5))
            }
        #endif
        
        if error != nil {
            error.memory = closureError
        }
        
        return response!
    }
    
    func connectWithHTTP(path: String, method: String, params: NSDictionary, headerFields: NSDictionary, success: (String) -> (Void), failure: (NSError) -> (Void)) -> NSOperation? {
        commonLogging(path, method: method, params: params, headerFields: headerFields)
        
        var parameters:NSDictionary?
        if method == "GET" || method == "DELETE" {
            parameters = params
        }
        
        var manager:AFHTTPRequestOperationManager = AFHTTPRequestOperationManager()
        
        var error:NSError?
        var request:NSMutableURLRequest = manager.requestSerializer.requestWithMethod(method, URLString:path, parameters:parameters, error:&error)
        
        if error != nil {
            failure(error!)
            return nil
        }
        
        if method == "POST" || method == "PUT" {
            var data:NSData = NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions.PrettyPrinted, error:&error)
            if error != nil {
                failure(error!)
                return nil
            }
            request.HTTPBody = data
        }
        
        if headerFields != nil {
            request.allHTTPHeaderFields = headerFields
        }
        
        var operation:AFHTTPRequestOperation = manager.HTTPRequestOperationWithRequest(request,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                NetworkActivityIndicatorManager.sharedInstance().hide()
                success(operation.responseString)
                
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                NetworkActivityIndicatorManager.sharedInstance().hide()
                failure(operation.error)
            })
        NetworkActivityIndicatorManager.sharedInstance().show()
        operation.start()
        return operation
    }
    
    func commonLogging(path: String, method: String, params: NSDictionary, headerFields: NSDictionary) {
        var baasio:Baasio = Baasio.sharedInstance()
        if baasio.isDebugMode() {
            let urlPrefix = baasio.getAPIURL().absoluteString
            println("- Start ---------------------------------------")
            if path.hasPrefix("http://") || path.hasPrefix("https://") {
                println("url : \(path)")
            } else {
                println("url : \(urlPrefix)/\(path)")
            }
            
            println("method : \(method)")
            println("params : \(params.description)")
            println("header : \(headerFields.description)")
            println("-----------------------------------------------")
        }
    }
}
