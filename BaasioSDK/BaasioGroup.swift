//
//  BaasioGroup.swift
//  baas.io-sdk-ios-swift
//
//  Created by kimkkikki on 2014. 6. 16..
//  Copyright (c) 2014년 baas.io. All rights reserved.
//

import Foundation

class BaasioGroup : BaasioEntity {
    var _user:String?
    var _group:String?
    
    init() {
        super.init()
        entityName = "groups"
    }
    
    func setGroupName(group:String) {
        _group = group
    }
    
    func setUserName(user:String) {
        _user = user
    }
    
    func add(error:NSErrorPointer) {
        let path:String = "groups/\(_group)/users/\(_user)"
        BaasioNetworkManager.sharedInstance().connectWithHTTPSync(path, method:"POST", params:nil!, error:error)
    }
    
    func addInBackground(success:(BaasioGroup) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        let path:String = "groups/\(_group)/users/\(_user)"
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"POST", params:nil!, success:{ (result:AnyObject) in
            var dictionary:NSDictionary = result["entities"]![0] as NSDictionary
            var group:BaasioGroup = BaasioGroup()
            group.set(dictionary)
            success(group)
            }, failure:failure)!
    }
    
    func remove(error:NSErrorPointer) {
        let path:String = "groups/\(_group)/users/\(_user)"
        BaasioNetworkManager.sharedInstance().connectWithHTTPSync(path, method:"DELETE", params:nil!, error:error)
    }
    
    func removeInBackground(success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        let path:String = "groups/\(_group)/users/\(_user)"
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"DELETE", params:nil!, success:{ (result:AnyObject) in
            success()
            }, failure:failure)!
    }
    
    func getInBackground(uuid:String, success:(BaasioGroup) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        return BaasioFile.getInBackground("groups", uuid:uuid, success:{ (entity:BaasioEntity) in
            var group:BaasioGroup = BaasioGroup()
            group.set(entity.dictionary)
            success(group)
            }, failure:failure)
    }
    
    class func get(uuid:String, error:NSErrorPointer) -> BaasioGroup {
        var entity:BaasioEntity = super.get("groups", uuid:uuid, error:error)
        var group:BaasioGroup = BaasioGroup()
        group.set(entity.dictionary)
        return group
    }
    
    override func save(error:NSErrorPointer) -> BaasioGroup {
        var entity:BaasioEntity = super.save(error)
        var group:BaasioGroup = BaasioGroup()
        group.set(entity.dictionary)
        return group
    }
    
    override func saveInBackground(success: (BaasioGroup) -> (Void), failure: (NSError) -> (Void)) -> NSOperation  {
        return super.saveInBackground({ (entity:BaasioEntity) in
            var group:BaasioGroup = BaasioGroup()
            group.set(entity.dictionary)
            success(group)
        }, failure:failure)
    }
    
    override func update(error: NSErrorPointer) -> BaasioEntity  {
        var entity:BaasioEntity = super.update(error)
        var group:BaasioGroup = BaasioGroup()
        group.set(entity.dictionary)
        return group
    }
    
    override func updateInBackground(success: (BaasioGroup) -> (Void), failure: (NSError) -> (Void)) -> NSOperation  {
        return super.updateInBackground({ (entity:BaasioEntity) in
            var group:BaasioGroup = BaasioGroup()
            group.set(entity.dictionary)
            success(group)
            }, failure:failure)
    }
}
