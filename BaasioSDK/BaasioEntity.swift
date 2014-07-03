//
//  BaasioEntity.swift
//  baas.io-sdk-ios-swift
//
//  Created by kimkkikki on 2014. 6. 10..
//  Copyright (c) 2014년 baas.io. All rights reserved.
//

import Foundation

class BaasioEntity: NSObject {
    var entityName:String?
    var uuid:String? {
        get {
            return _entity["uuid"] as? String
        }
        set {
            _entity["uuid"] = newValue
        }
    }
    let created:NSDate?
    let modified:NSDate?
    var type:String? {
        return _entity["type"] as? String
    }
    var _entity:NSMutableDictionary = NSMutableDictionary()
    
    func set(entity:NSDictionary) {
        _entity.removeAllObjects()
        _entity.setDictionary(entity)
    }

    class func entityWithName(entityName: String) -> BaasioEntity {
        var entity:BaasioEntity = BaasioEntity()
        entity.entityName = entityName
        return entity
    }
    
    func connect(entity: BaasioEntity, relationship: String, error: NSErrorPointer) {
        let path = "\(entityName)/\(uuid)/\(relationship)/\(entity.entityName)/\(entity.uuid)"
        
        BaasioNetworkManager.sharedInstance().connectWithHTTPSync(path, method:"POST", params:_entity, error:error)
    }
    
    func connectInBackground(entity:BaasioEntity, relationship:String, success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation? {
        let path:String = "\(entityName)/\(uuid)/\(relationship)/\(entity.entityName)/\(entity.uuid)"
        
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"POST", params:_entity,
            success: { (response:AnyObject!) in
                success()
            },
            failure:failure)
    }
    
    func disconnect(entity:BaasioEntity, relationship:String, error:NSErrorPointer) {
        let path:String = "\(entityName)/\(uuid)/\(relationship)/\(entity.entityName)/\(entity.uuid)"
        BaasioNetworkManager.sharedInstance().connectWithHTTPSync(path, method:"DELETE", params:_entity, error:error)
    }
    
    func disconnectInBackground(entity:BaasioEntity, relationship:String, success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        let path:String = "\(entityName)/\(uuid)/\(relationship)/\(entity.entityName)/\(entity.uuid)"
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"DELETE", params:_entity,
            success: { (response:AnyObject!) -> Void in
                success()
            },
            failure:failure)!
    }
    
    // MARK: - Data
    func objectForKey(key:String) -> AnyObject? {
        return _entity[key]
    }
    
    func setObject(value:AnyObject, forKey:String) {
        if value.isMemberOfClass(BaasioFile) || value.isMemberOfClass(BaasioUser) {
            var entity = value as BaasioEntity
            _entity.setObject(entity.dictionary, forKey:forKey)
        } else {
            _entity.setObject(value, forKey:forKey)
        }
    }
    
    // MARK: - Entity
    class func get(entityName:String, uuid:String, error:NSErrorPointer) -> BaasioEntity {
        let path:String = "\(entityName)/\(uuid)"
        return BaasioNetworkManager.sharedInstance().connectWithHTTPSync(path, method:"GET", params:nil, error:error) as BaasioEntity
    }
    
    class func getInBackground(entityName:String, uuid:String, success:(BaasioEntity) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        let path:String = "\(entityName)/\(uuid)"
        
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"DELETE", params:nil,
            success: { (result:AnyObject!) -> Void in
                let response:NSDictionary = result as NSDictionary
                var entities = response["entities"] as NSArray
                var dictionary = entities[0] as NSDictionary
                var type:String = dictionary["type"] as String
                
                var entity:BaasioEntity = BaasioEntity.entityWithName(type)
                entity.set(dictionary)
                
                success(entity)
            },
            failure:failure)!
    }
    
    func save(error:NSErrorPointer) -> BaasioEntity {
        return BaasioNetworkManager.sharedInstance().connectWithHTTPSync(entityName!, method:"POST", params:_entity, error:error) as BaasioEntity
    }
    
    func saveInBackground(success:(BaasioEntity) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(entityName!, method:"POST", params:_entity,
            success: { (result:AnyObject!) -> Void in
                var response:NSDictionary = result as NSDictionary
                
                var entities = response["entities"] as NSArray
                var dictionary = entities[0] as NSDictionary
                var type:String = dictionary["type"] as String
                
                var entity:BaasioEntity = BaasioEntity.entityWithName(type)
                entity.set(dictionary)
                
                success(entity)
            },
            failure:failure)!
    }
    
    // delete라는 기본 메소드가 추가됨으로 인해 이름 변경
    func deleteEntity(error:NSErrorPointer) {
        let path:String = "\(entityName)/\(uuid)"
        BaasioNetworkManager.sharedInstance().connectWithHTTPSync(path, method:"DELETE", params:nil, error:error)
    }
    
    func deleteEntityInBackground(success:(Void) -> (Void), failure:(NSError) -> (Void)) {
        let path:String = "\(entityName)/\(uuid)"
        BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"DELETE", params:nil,
            success: { (result:AnyObject!) -> Void in
                success()
            },
            failure:failure)!
    }
    
    func update(error:NSErrorPointer) -> BaasioEntity {
        return BaasioNetworkManager.sharedInstance().connectWithHTTPSync(entityName!, method:"PUT", params:_entity, error:error) as BaasioEntity
    }
    
    func updateInBackground(success:(BaasioEntity) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        let path:String = "\(entityName)/\(uuid)"
        
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"PUT", params:_entity,
            success: { (result:AnyObject!) -> Void in
                let response:NSDictionary = result as NSDictionary
                var entities = response["entities"] as NSArray
                var dictionary = entities[0] as NSDictionary
                var type:String = dictionary["type"] as String
                
                var entity:BaasioEntity = BaasioEntity.entityWithName(type)
                entity.set(dictionary)
                
                success(entity)
            },
            failure:failure)!
    }
    
    // MARK: - Super
    override var description:String {
        return _entity.description
    }
    
    // MARK: - Etc
    var dictionary:NSDictionary {
        return _entity
    }
    
    // created, modified 메소드 invalid로 인해 이름 변경
    var entityCreated:String {
        return _entity["created"] as String
    }
    
    var entityModified:String {
        return _entity["modified"] as String
    }
    
    func getUuid() -> String {
        return _entity["uuid"] as String
    }
    
    func getType() -> String {
        return _entity["type"] as String
    }
    
    func setUuid(uuid:String) {
        _entity["uuid"] = uuid
    }
}