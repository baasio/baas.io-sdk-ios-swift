//
//  BaasioQuery.swift
//  baas.io-sdk-ios-swift
//
//  Created by kimkkikki on 2014. 6. 13..
//  Copyright (c) 2014년 baas.io. All rights reserved.
//

import Foundation

let PAGE_EOF_STRING = "END"

enum BaasioQuerySortOrder {
    case ASC
    case DESC
}

class BaasioQuery: NSObject {
    var _collectionName:String?
    var _projectionIn:String?
    var _wheres:String?
    var _orderKey:String?
    var _group:String?
    var _relation:String?
    var _cursors:NSMutableArray = NSMutableArray.array()
    var _order:BaasioQuerySortOrder?
    var _limit:Int?
    var _pos:Int = -1
    
    class func queryWithCollection(name:String) -> BaasioQuery {
        return BaasioQuery(collectionName:name)
    }
    
    class func queryWithGroup(name:String) -> BaasioQuery {
        return BaasioQuery(groupName:name)
    }
    
    class func queryWithRelationship(entityName:String, uuid:String, relationName:String) -> BaasioQuery {
        let path = "\(entityName)/\(uuid)/\(relationName)"
        return BaasioQuery.queryWithCollection(path)
    }
    
    init(collectionName:String) {
        super.init()
        _collectionName = collectionName
    }
    
    init(groupName:String) {
        super.init()
        _group = groupName
    }
    
    func setProjectionIn(projectionIn:String) {
        _projectionIn = projectionIn
    }
    
    func setWheres(wheres:String) {
        _wheres = wheres
    }
    
    func setOrderBy(key:String, order:BaasioQuerySortOrder) {
        _orderKey = key
        _order = order
    }
    
    func setLimit(limit:Int) {
        _limit = limit
    }
    
    func cursor() -> NSString {
        if _pos == -1 {
            return ""
        }
        return _cursors[_pos] as String
    }
    
    func setCursor(cursor:String) {
        _pos = 0
        _cursors[_pos] = cursor
    }
    
    func clearCursor() {
        _pos = -1
        _cursors = NSMutableArray.array()
    }
    
    func hasMoreEntities() -> Bool {
        if _pos == -1 {
            return false
        } else if _cursors[_pos] == nil {
            return false
        } else if _cursors[_pos] as String == PAGE_EOF_STRING {
            return false
        }
        return true
    }
    
    func description() -> String {
        var ql:String = "?ql=select "
        if _projectionIn != nil {
            ql = "\(ql)\(_projectionIn)"
        } else {
            ql = "\(ql)*"
        }
        
        if _wheres != nil {
            ql = "\(ql) where \(_wheres)"
        }
        
        if _orderKey != nil {
            var order = _order == BaasioQuerySortOrder.DESC ? "desc" : "asc"
            ql = "\(ql) order by \(_orderKey) \(order)"
        }
        
        ql = "?ql=\(ql)"
        
        if _limit != 0 || _limit != 10 {
            ql = "\(ql)&limit=\(_limit)"
        }
        
        if _pos != -1 && _cursors[_pos] as String != PAGE_EOF_STRING {
            ql = "\(ql)&curosr=\(_cursors[_pos])"
        }
        
        return ql
    }
    
    func query(error:NSErrorPointer) -> NSArray {
        var prefixPath:String = _collectionName!
        if _group != nil {
            prefixPath = "groups/\(_group)/users"
        }
        
        var path:String = "\(prefixPath)\(description())"
        
        var response:NSDictionary = BaasioNetworkManager.sharedInstance().connectWithHTTPSync(path, method:"GET", params:nil, error:error) as NSDictionary
        
        var objects:NSArray = parseQueryResponse(response)
        return objects
    }
    
    func parseQueryResponse(response:NSDictionary) -> NSArray {
        var cursor:String = response["cursor"] as String
        if cursor != nil {
            _cursors[++_pos] = response["cursor"]
        } else {
            if _pos == -1 || _cursors[_pos] as NSObject != PAGE_EOF_STRING {
                _cursors[++_pos] = PAGE_EOF_STRING
            }
        }
        var objects:NSArray = NSArray(array:response["entities"] as AnyObject[]!)
        return objects
    }
    
    func queryInBackground(success:(NSArray) -> (Void), failure:(NSError) -> (Void)) -> NSOperation? {
        var prefixPath:String = _collectionName!
        if _group != nil {
            prefixPath = "group/\(_group)users"
        }
        
        let path = "\(prefixPath)\(description())"
        
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"GET", params:nil, success:{
            (result:AnyObject) in
            var response:NSDictionary = result as NSDictionary
            var objects:NSArray = self.parseQueryResponse(response)
            }, failure:failure)
    }
    
    func next(error:NSErrorPointer) -> NSArray {
        if !hasMoreEntities() {
            var details:NSMutableDictionary = NSMutableDictionary.dictionary()
            details.setValue("Next entities isn't exist.", forKey:NSLocalizedDescriptionKey)
            
            var e:NSError = NSError.errorWithDomain("BaasioError", code:UNKNOWN_ERROR, userInfo:details)
            error.memory = e
            return nil!
        }
        return query(error)
    }
    
    func nextInBackground(success:(NSArray) -> (Void), failure:(NSError) -> (Void)) -> NSOperation? {
        if !hasMoreEntities() {
            var details:NSMutableDictionary = NSMutableDictionary.dictionary()
            details.setValue("Next entities isn't exist.", forKey:NSLocalizedDescriptionKey)
            
            var e:NSError = NSError.errorWithDomain("BaasioError", code:UNKNOWN_ERROR, userInfo:details)
            failure(e)
            return nil
        }
        return queryInBackground(success, failure:failure)
    }
    
    func prev(error:NSErrorPointer) -> NSArray {
        _pos -= 2
        if _pos == -1 {
            clearCursor()
        } else if _pos < -1 {
            var details:NSMutableDictionary = NSMutableDictionary.dictionary()
            details.setValue("Next entities isn't exist.", forKey:NSLocalizedDescriptionKey)
            
            var e:NSError = NSError.errorWithDomain("BaasioError", code:UNKNOWN_ERROR, userInfo:details)
            error.memory = e
            return nil!
        }
        return query(error)
    }
    
    func prevInBackground(success:(NSArray) -> (Void), failure:(NSError) -> (Void)) -> NSOperation? {
        _pos -= 2
        if _pos == -1 {
            clearCursor()
        } else if _pos < -1 {
            var details:NSMutableDictionary = NSMutableDictionary.dictionary()
            details.setValue("Next entities isn't exist.", forKey:NSLocalizedDescriptionKey)
            
            var e:NSError = NSError.errorWithDomain("BaasioError", code:UNKNOWN_ERROR, userInfo:details)
            failure(e)
            return nil
        }
        return queryInBackground(success, failure:failure)
    }
}
