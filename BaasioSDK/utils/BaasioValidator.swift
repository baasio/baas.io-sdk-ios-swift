//
//  BaasioValidator.swift
//  baas.io-sdk-ios-swift
//
//  Created by kimkkikki on 2014. 6. 13..
//  Copyright (c) 2014년 baas.io. All rights reserved.
//

import Foundation

class BaasioValidator : NSObject {
    class func parameterValidation(dictionary:NSDictionary, validateKeys:NSArray) -> NSError? {
        var allKeys:NSArray = dictionary.allKeys
        for i in 0...validateKeys.count-1 {
            if !allKeys.containsObject(validateKeys[i]) {
                var key:String = validateKeys[i] as String
                var message:String = "The method requires a property named '\(key)'"
//                var message:String = "The '\(NSStringFromSelector(selector))' method requires a property named '\(key)'"
                var details:NSMutableDictionary = NSMutableDictionary()
                details.setValue(message, forKey:NSLocalizedDescriptionKey)
                var e:NSError = NSError.errorWithDomain("BaasioError", code:MISSING_REQUIRED_PROPERTY_ERROR, userInfo:details)
                return e
            }
        }
        return nil
    }
}