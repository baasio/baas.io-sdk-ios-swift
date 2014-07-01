//
//  Baasio.swift
//  baas.io-sdk-ios-swift
//
//  Created by kimkkikki on 2014. 6. 9..
//  Copyright (c) 2014년 baas.io. All rights reserved.
//

import Foundation

class Baasio: NSObject {
    var apiUrl:String?
    var baasioID:String?
    var applicationName:String?
    var token:String?
    var currentUser:BaasioUser?
    var debugMode:Bool = false
    
    class func sharedInstance() -> Baasio! {
        struct Static {
            static var token : dispatch_once_t = 0
            static var instance : Baasio? = nil
        }
        
        dispatch_once(&Static.token) { Static.instance = Baasio() };
        return Static.instance!
    }
    
    class func setApplicationInfo(baasioID: String, applicationName:String) {
        let url = "https://api.baas.io"
        Baasio.setApplicationInfo(url, baasioID: baasioID, applicationName: applicationName)
    }
    
    class func setApplicationInfo(apiUrl: String, baasioID: String, applicationName: String) {
        let baasio:Baasio = Baasio.sharedInstance()
        baasio.apiUrl = apiUrl
        baasio.baasioID = baasioID
        baasio.applicationName = applicationName
        
        
        let savedToken:String? = NSUserDefaults.standardUserDefaults().objectForKey("access_token") as? String
        let savedUser:NSDictionary? = NSUserDefaults.standardUserDefaults().objectForKey("login_user") as? NSDictionary
        
        if savedToken != nil && savedUser != nil {
            baasio.token = savedToken!
            var loginUser = BaasioUser()
            loginUser.set(savedUser!)
            baasio.currentUser = loginUser
        }
    }

    func getAPIURL() -> NSURL {
        return NSURL.URLWithString("\(apiUrl)/\(baasioID)/\(applicationName)")
    }
    
    func hasToken() -> Bool {
        if token == nil || token == "" {
            return false
        }
        return true
    }
    
    func getToken() -> String? {
        return token
    }
    
    func setCurrentUser(user:BaasioUser) {
        currentUser = user
    }
    
    func isDebugMode() -> Bool {
        return debugMode
    }
    
    func setAuthorization(request: NSMutableURLRequest) -> NSMutableURLRequest {
        if token != nil {
            request.addValue("Bearer \(token)", forHTTPHeaderField:"Authorization")
        }
        
        return request
    }
}

