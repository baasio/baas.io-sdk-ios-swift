//
//  BaasioHelp.swift
//  baas.io-sdk-ios-swift
//
//  Created by kimkkikki on 2014. 6. 16..
//  Copyright (c) 2014년 baas.io. All rights reserved.
//

import Foundation

class BaasioHelp : NSObject {
    func getHelpsInBackground(success:(NSArray) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        return searchHelpsInBackground("", success:success, failure:failure)
    }
    
    func searchHelpsInBackground(keyword:String, success:(NSArray) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        var param:NSDictionary = ["keyword":keyword]
        
        return BaasioNetworkManager.sharedInstance().connectWithHTTP("help/helps", method:"GET", params:param, success:{ (result:AnyObject) in
            var response:NSDictionary = result as NSDictionary
            var objects:NSArray = NSArray(array:response["entities"] as NSArray)
            success(objects)
            }, failure:failure)!
    }
    
    func getHelpDetailInBackground(uuid:String, success:(NSDictionary) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        let path:String = "help/helps/\(uuid)"
        
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"GET", params:nil!, success:{ (result:AnyObject) in
            var response:NSDictionary = result as NSDictionary
            var objects:NSArray = NSArray(array:response["entities"] as NSArray)
            success(objects[0] as NSDictionary)
            }, failure:failure)!
    }
    
    func sendQuestionInBackground(email:String, content:String, success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        var param = ["email":email,
            "content":content,
            "temporary_answer":"temporary_answer",
            "classification_id":"classification_id",
            "satisfaction_level_id":"satisfaction_level_id",
            "status_id":"status_id", "device_info":"device_info",
            "official":"official",
            "publicaccessable":"publicaccessable",
            "app_info":"app_info",
            "os_info":"os_info",
            "platform":"platform",
            "vote":"1",
            "tags":""]

        let path:String = "help/questions"
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"POST", params:param, success:{ (result:AnyObject) in
            success()
            }, failure:failure)!
    }
}
