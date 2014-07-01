//
//  NetworkActivityIndicatorManager.swift
//  baas.io-sdk-ios-swift
//
//  Created by kimkkikki on 2014. 6. 10..
//  Copyright (c) 2014년 baas.io. All rights reserved.
//

import Foundation

class NetworkActivityIndicatorManager: NSObject {
    var application:UIApplication = UIApplication.sharedApplication()
    var count:Int = 0
    
    class func sharedInstance() -> NetworkActivityIndicatorManager! {
        struct Static {
            static var token : dispatch_once_t = 0
            static var instance : NetworkActivityIndicatorManager? = nil
        }
        
        dispatch_once(&Static.token) { Static.instance = NetworkActivityIndicatorManager() };
        return Static.instance!
    }
    
    func synced(lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    func show () {
        synced(self, closure: {
            self.count++
            self.application.networkActivityIndicatorVisible = true
        })
    }
    
    func hide() {
        synced(self, closure: {
            if self.count <= 1 {
                self.count = 0
            } else {
                self.count -= 1
                return
            }
            self.application.networkActivityIndicatorVisible = false
        })
    }
    
    func forceShow() {
        synced(self, closure: {
            self.count = 0
            self.show()
            })
    }
    
    func forceHide() {
        synced(self, closure: {
            self.count = 0
            self.hide()
        })
    }
}
