//
//  ShadowUpdateChecker.swift
//  baas.io-sdk-ios-swift
//
//  Created by kimkkikki on 2014. 6. 9..
//  Copyright (c) 2014년 baas.io. All rights reserved.
//

import Foundation

let GITHUB_TAGS_LIST = "https://api.github.com/repos/baasio/baas.io-sdk-ios/tags"

class ShadowUpdateChecker: NSObject {
    
    func check() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            if !Baasio.sharedInstance().isDebugMode() {
                return
            }
            
            NSThread.sleepForTimeInterval(1)
            var error:NSError?
            var latestVersion:String = self.latestVersion(&error)
            var currentVersion:String = self.currentSDKVersion()
            
            if error != nil {
                println("Fail to get new version : \(error!.localizedDescription)")
                return
            }
            
            if latestVersion == currentVersion {
                for index in 1...50 {
                    println("★☆★☆ The new Baas.io SDK Release. see this link https://github.com/baasio/baas.io-sdk-ios (current : \(currentVersion), new : \(latestVersion)) ★☆★☆")
                }
            }
        })
    }
    
    func currentSDKVersion () -> String {
        return BAASIO_SDK_VERSION_STRING
    }
    
    func latestVersion(error: NSErrorPointer) -> String {
        var response:String = SimpleNetworkManager.sharedInstance().connectWithHTTPSync(GITHUB_TAGS_LIST, method:"GET", params:nil!, headerFields:nil!, error:error)
        
        var data:NSData = response.dataUsingEncoding(NSUTF8StringEncoding)
        var array:AnyObject = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments, error:error)
        var dictionary:NSDictionary = array[0]! as NSDictionary
        
        return dictionary["name"]! as String
    }
}