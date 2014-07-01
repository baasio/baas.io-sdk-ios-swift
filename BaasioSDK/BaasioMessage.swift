//
//  BaasioMessage.swift
//  baas.io-sdk-ios-swift
//
//  Created by kimkkikki on 2014. 6. 16..
//  Copyright (c) 2014년 baas.io. All rights reserved.
//

import Foundation

class BaasioMessage : NSObject {
    var target:String = "all"
    var badge:Int = 1
    var sound:String?
    var alert:String?
    var platform:String = "I,G"
    var memo:String = "iOS SDK"
    var reserve:NSDateComponents?
    var to:NSArray?
    var _payload:NSMutableDictionary = NSMutableDictionary.dictionary()
    let path:String = "pushes"
    
    func payload() -> NSDictionary {
        var payload:NSMutableDictionary = _payload
        payload.setValue(String(badge), forKey:"badge")
        payload.setValue(sound, forKey:"sound")
        payload.setValue(alert, forKey:"alery")
        
        return payload
    }
    
    func reserveDate() -> String {
        var dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmm"
        return dateFormatter.stringFromDate(NSCalendar.currentCalendar().dateFromComponents(reserve))
    }
    
    func dictionary() -> NSDictionary {
        var dictionary:NSDictionary = ["target":target, "payload":payload(), "platform":platform, "memo":memo]
        var _mictionary:NSMutableDictionary = NSMutableDictionary(dictionary:dictionary)
        if to != nil && to!.count != 0 {
            var toList:NSString = to.description
            toList = toList.stringByReplacingOccurrencesOfString("\n", withString:"")
            toList = toList.stringByReplacingOccurrencesOfString("\\", withString:"")
            let length:Int = toList.length - 2
            toList = toList.substringWithRange(NSMakeRange(1, length))
            _mictionary.setObject(toList, forKey:"to")
        }
        
        if reserve != nil {
            _mictionary.setObject(reserveDate(), forKey:"reserve")
        }
        
        return _mictionary
    }
    
    func addPayload(value:String, forKey:String) {
        _payload.setValue(value, forKey:forKey)
    }
}