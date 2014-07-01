//
//  BaasioPush.swift
//  baas.io-sdk-ios-swift
//
//  Created by kimkkikki on 2014. 6. 16..
//  Copyright (c) 2014년 baas.io. All rights reserved.
//

import Foundation
import UIKit

let PUSH_DELIMETER = "\\b"
let PUSH_API_ENDPOINT = "devices"
let PUSH_DEVICE_ID = "PUSH_DEVICE_ID_BAASIO_SDK"

class BaasioPush : NSObject {
    func storedPushDeviceID() -> String? {
        var array:NSArray = storedPushDeviceString()
        return array[0] as? String
    }
    
    func storedPushUserUUID() -> String? {
        var array:NSArray = storedPushDeviceString()
        if array.count == 1 {
            return nil
        }
        return array[1] as? String
    }
    
    func storedPushDeviceString() -> NSArray {
        var deviceString:String = NSUserDefaults.standardUserDefaults().objectForKey(PUSH_DEVICE_ID) as String
        return deviceString.componentsSeparatedByString(PUSH_DELIMETER)
    }
    
    func storedPushDeviceInfo(deviceID:String) {
        var user:String = ""
        var currentUser:BaasioUser = BaasioUser.currentUser()
        if currentUser != nil {
            user = currentUser.uuid!
            
            var pushDeviceInfo:String = "\(deviceID)\(PUSH_DELIMETER)\(user)"
            NSUserDefaults.standardUserDefaults().setObject(pushDeviceInfo, forKey:PUSH_DEVICE_ID)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    func sendPush(message:BaasioMessage, error:NSErrorPointer) -> AnyObject {
        var params:NSDictionary = message.dictionary()
        return BaasioNetworkManager.sharedInstance().connectWithHTTPSync("pushes", method:"POST", params:params, error:error)
    }
    
    func sendPushInBackground(message:BaasioMessage, success:(AnyObject) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        var params:NSDictionary = message.dictionary()
        return BaasioNetworkManager.sharedInstance().connectWithHTTP("pushes", method:"POST", params:params, success:{ (result:AnyObject) in
            var response:NSDictionary = result as NSDictionary
            var dictionary:NSDictionary = response["entities"]![0] as NSDictionary
            success(dictionary)
            }, failure:failure)!
    }
    
    func cancelReservedPush(uuid:String, error:NSErrorPointer) {
        let path:String = "pushes/\(uuid)"
        BaasioNetworkManager.sharedInstance().connectWithHTTPSync(path, method:"DELETE", params:nil!, error:error)
    }
    
    func cancelReservedPushInBackground(uuid:String, success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        let path:String = "pushes/\(uuid)"
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"DELETE", params:nil!, success:{ (result:AnyObject) in
            success()
            }, failure:failure)!
    }
    
    class func registerUserNotificationSettings(settings:UIUserNotificationSettings) {
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    
    // deprecated in iOS 8.0
    class func registerForRemoteNotificationTypes(types:UIRemoteNotificationType) {
        UIApplication.sharedApplication().registerForRemoteNotificationTypes(types)
    }
    
    func unregisterForRemoteNotifications(success:(Void) -> (Void), failure:(NSError) -> (Void)) {
        unregisterInBackground({ (Void) in
            UIApplication.sharedApplication().unregisterForRemoteNotifications()
            }, failure:failure)
    }
    
    func unregister(error:NSErrorPointer) {
        let deviceID:String? = storedPushDeviceID()
        if deviceID == nil {
            return
        }
        
        let path:String = "\(PUSH_API_ENDPOINT)/\(deviceID)"
        BaasioNetworkManager.sharedInstance().connectWithHTTPSync(path, method:"DELETE", params:nil!, error:error)
    }
    
    func unregisterInBackground(success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        var deviceID:String? = storedPushDeviceID()
        if deviceID == nil {
            success()
            return nil!
        }
        
        let path:String = "\(PUSH_API_ENDPOINT)/\(deviceID)"
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"DELETE", params:nil!, success:{ (result:AnyObject) in
            success()
            }, failure:failure)!
    }
    
    func didRegisterForRemoteNotifications(deviceToken:NSData, tags:NSArray, success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        var tag:NSArray = tags
        if tag == nil {
            tag = NSArray.array()
        }
        
        //    NSMutableString *deviceID = [NSMutableString string];
        //    const unsigned char* ptr = (const unsigned char*) [deviceToken bytes];
        //    for(int i = 0 ; i < 32 ; i++)
        //    {
        //        [deviceID appendFormat:@"%02x", ptr[i]];
        //    }
        var deviceID:String = NSString(data:deviceToken, encoding:NSUTF8StringEncoding)
        
        if let oldDeviceID = storedPushDeviceID() {
            println("baasioPush : Already registration")
            var currentUser:String? = BaasioUser.currentUser().uuid
            var storedUser:String? = storedPushUserUUID()
            
            if storedUser == nil {
                storedUser = ""
            }
            
            if currentUser == nil {
                currentUser = ""
            }
            
            if deviceID == oldDeviceID && storedUser == currentUser {
                println("baasioPush : No Change")
                success()
                return nil!
            } else {
                println("baasioPush : Something change")
                let params:NSDictionary = ["token":deviceID, "tags":tag]
                let path:String = "\(PUSH_API_ENDPOINT)/\(oldDeviceID)"
                return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"PUT", params:params, success:{ (result:AnyObject) in
                    self.storedPushDeviceInfo(deviceID)
                    success()
                    }, failure:failure)!
            }
        } else {
            println("baasioPush : First registraion")
            return registerForFirst(tag, deviceID:deviceID, success:success, failure:failure)
        }
    }
    
    func registerForFirst(tags:NSArray, deviceID:String, success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        let params = ["token":deviceID, "platform":"I", "tags":tags]
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(PUSH_API_ENDPOINT, method:"POST", params:params, success:{ (result:AnyObject) in
            self.storedPushDeviceInfo(deviceID)
            success()
            }, failure:{ (error:NSError) in
                if error.code == DUPLICATED_UNIQUE_PROPERTY_ERROR {
                    let path:String = "\(PUSH_API_ENDPOINT)/\(deviceID)"
                    BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"PUT", params:params, success:{ (result:AnyObject) in
                        self.storedPushDeviceInfo(deviceID)
                        success()
                        }, failure:failure)!
                } else {
                    failure(error)
                }
            })!
    }
    
    func tagUpdate(tags:NSArray, error:NSErrorPointer) {
        let deviceID = storedPushDeviceID()
        if deviceID == nil {
            return
        }
        
        let path = "\(PUSH_API_ENDPOINT)/\(deviceID)"
        let params = ["tags":tags]
        
        BaasioNetworkManager.sharedInstance().connectWithHTTPSync(path, method:"PUT", params:params, error:error)
    }
    
    func tagUpdateInBackground(tags:NSArray, success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        let deviceID = storedPushDeviceID()
        if deviceID == nil {
            success()
            return nil!
        }
        
        let path = "\(PUSH_API_ENDPOINT)/\(deviceID)"
        let params = ["tags":tags]
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"PUT", params:params, success:{ (result:AnyObject) in
            success()
            }, failure:failure)!
    }
    
    func pushOn(error:NSErrorPointer) {
        let deviceID = storedPushDeviceID()
        if deviceID == nil {
            return
        }
        
        let path = "\(PUSH_API_ENDPOINT)/\(deviceID)"
        let params = ["state":true]
        BaasioNetworkManager.sharedInstance().connectWithHTTPSync(path, method:"PUT", params:params, error:error)
    }
    
    func pushOnInBackground(success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        let deviceID = storedPushDeviceID()
        if deviceID == nil {
            success()
            return nil!
        }
        
        let path = "\(PUSH_API_ENDPOINT)/\(deviceID)"
        let params = ["state":true]
        
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"PUT", params:params, success:{ (result:AnyObject) in
            success()
            }, failure:failure)!
    }
    
    func pushOff(error:NSErrorPointer) {
        let deviceID = storedPushDeviceID()
        if deviceID == nil {
            return
        }
        
        let path = "\(PUSH_API_ENDPOINT)/\(deviceID)"
        let params = ["state":false]
        BaasioNetworkManager.sharedInstance().connectWithHTTPSync(path, method:"PUT", params:params, error:error)
    }
    
    func pushOffInBackground(success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        let deviceID = storedPushDeviceID()
        if deviceID == nil {
            success()
            return nil!
        }
        
        let path = "\(PUSH_API_ENDPOINT)/\(deviceID)"
        let params = ["state":false]
        
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"PUT", params:params, success:{ (result:AnyObject) in
            success()
            }, failure:failure)!
    }
}