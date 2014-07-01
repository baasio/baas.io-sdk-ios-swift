//
//  BaasioUser.swift
//  baas.io-sdk-ios-swift
//
//  Created by kimkkikki on 2014. 6. 9..
//  Copyright (c) 2014년 baas.io. All rights reserved.
//

import Foundation

class BaasioUser :BaasioEntity {
    var username:String? {
        return objectForKey("username") as? String
    }
    
    init() {
        super.init()
        entityName = "users"
    }
    
    class func user() -> BaasioUser {
        return BaasioUser()
    }
    
    class func currentUser() -> BaasioUser {
        return Baasio.sharedInstance().currentUser!
    }
    
    override func update(error:NSErrorPointer) -> BaasioUser {
        let entity:BaasioEntity = super.update(error)
        var user:BaasioUser = BaasioUser()
        user.set(entity.dictionary)
        
        return user
    }
    
    override func updateInBackground(success: (BaasioEntity) -> (Void), failure: (NSError) -> (Void)) -> NSOperation {
        return super.updateInBackground({ (entity:BaasioEntity) -> (Void) in
                var user:BaasioUser = BaasioUser()
                user.set(entity.dictionary)
                success(user)
            }, failure:failure)
    }
    
    class func signOut() {
        Baasio.sharedInstance().currentUser = nil
        Baasio.sharedInstance().token = nil
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey:"access_token")
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey:"login_user")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func unsubscribe(error:NSErrorPointer) {
        let path:String = "users/\(BaasioUser.currentUser().uuid)"
        BaasioNetworkManager.sharedInstance().connectWithHTTPSync(path, method:"DELETE", params:nil!, error:error)
        BaasioUser.signOut()
    }
    
    func unsubscribeInBackground(success:(Void) -> (Void), failure:(NSError) -> (Void)) {
        let path:String = "users/\(BaasioUser.currentUser().uuid)"
        BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"DELETE", params:nil!, success: {
                (result:AnyObject!) -> Void in
                BaasioUser.signOut()
                success()
            }, failure:failure)
    }
    
    class func saveLoginInfomation(result:AnyObject) {
        var response:NSDictionary = result as NSDictionary
        Baasio.sharedInstance().token = response["access_token"] as? String
        
        var loginUser = BaasioUser.user()
        loginUser.set(response["user"] as NSDictionary)
        Baasio.sharedInstance().currentUser = loginUser
        
        NSUserDefaults.standardUserDefaults().setObject(response["access_token"], forKey:"access_token")
        NSUserDefaults.standardUserDefaults().setObject(response["user"], forKey:"login_user")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    class func signIn(username:String, password:String, error:NSErrorPointer) {
        let params = ["grant_type":"password", "username":username, "password":password]
        var result:AnyObject = BaasioNetworkManager.sharedInstance().connectWithHTTPSync("token", method:"POST", params:params, error:error)
        saveLoginInfomation(result)
    }
    
    class func signInBackground(username:String, password:String, success: (Void) -> (Void), failure: (NSError) -> (Void)) -> NSOperation {
        let params:NSDictionary = ["grant_type":"password", "username":username, "password":password]
        
        return BaasioNetworkManager.sharedInstance().connectWithHTTP("token", method:"POST", params:params, success: { (result:AnyObject!) -> Void in
                self.saveLoginInfomation(result)
                success()
            }, failure:failure)!
    }
    
    class func signUp(username:String, password:String, name:String, email:String, error:NSErrorPointer) {
        let params:NSDictionary = ["name":name, "password":password, "username":username, "email":email]
        BaasioNetworkManager.sharedInstance().connectWithHTTPSync("users", method:"POST", params:params, error:error)
    }
    
    class func signUpInBackground(username:String, password:String, name:String, email:String, success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        let params:NSDictionary = ["name":name, "password":password, "username":username, "email":email]
        return BaasioNetworkManager.sharedInstance().connectWithHTTP("users", method:"POST", params:params, success: { (result:AnyObject!) -> Void in
                success()
            }, failure:failure)!
    }
    
    func signUp(error:NSErrorPointer) {
        let validateKeys:NSArray = ["username", "password", "email", "name"]
        var e:NSError? = BaasioValidator.parameterValidation(dictionary, validateKeys:validateKeys)
        if e != nil {
            error.memory = e
            return
        }
        BaasioNetworkManager.sharedInstance().connectWithHTTPSync("users", method:"POST", params:dictionary, error:error)
    }
    
    func signUpInBackground(success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        let validateKeys:NSArray = ["username", "password", "email", "name"]
        var e:NSError? = BaasioValidator.parameterValidation(dictionary, validateKeys:validateKeys)
        if e != nil {
            failure(e!)
            return nil!
        }
        
        return BaasioNetworkManager.sharedInstance().connectWithHTTP("users", method:"POST", params:dictionary, success: { (result:AnyObject!) -> Void in
                success()
            }, failure:failure)!
    }
    
    class func changePassword(oldPassword:String, newPassword:String, error:NSErrorPointer) {
        let params = ["oldpassword":oldPassword, "newpassword":newPassword]
        
        var baasioUser:BaasioUser = BaasioUser.currentUser()
        if baasioUser == nil {
            error.memory = emptyUserError()
            return
        }
        
        let path:String = "users/\(baasioUser.uuid)/password"
        BaasioNetworkManager.sharedInstance().connectWithHTTPSync(path, method:"POST", params:params, error:error)
    }
    
    class func changePasswodInBackground(oldPassword:String, newPassword:String, success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        let params = ["oldpassword":oldPassword, "newpassword":newPassword]
        
        var baasioUser:BaasioUser = BaasioUser.currentUser()
        if baasioUser == nil {
            failure(emptyUserError())
            return nil!
        }
        
        let path:String = "users/\(baasioUser.uuid)/password"
        
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"POST", params:params, success: { (result:AnyObject!) -> Void in
                success()
            }, failure:failure)!
    }
    
    class func resetPassword(username:String, error:NSErrorPointer) {
        let path:String = "users/\(username)/resetpw"
        BaasioNetworkManager.sharedInstance().connectWithHTTPSync(path, method:"POST", params:nil!, error:error)
    }
    
    class func resetPasswordInBackground(username:String, success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        let path:String = "users/\(username)/resetpw"
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"POST", params:nil!, success: { (result:AnyObject!) -> Void in
            success()
        }, failure:failure)!
    }
    
    class func emptyUserError() -> NSError {
        let message:String = "The baasioUser was empty. Please login in first."
        var details:NSMutableDictionary = NSMutableDictionary.dictionary()
        details.setValue(message, forKey:NSLocalizedDescriptionKey)
        return NSError.errorWithDomain("BaasioError", code:BAD_TOKEN_ERROR, userInfo:details)
    }
    
    class func signUpViaFacebook(accessToken:String, error:NSErrorPointer) {
        let params = ["fb_access_token":accessToken]
        let path = "auth/facebook"
        var result:AnyObject = BaasioNetworkManager.sharedInstance().connectWithHTTPSync(path, method:"GET", params:params, error:error)
        saveLoginInfomation(result)
    }
    
    class func signUpViaFacebookInbackground(accessToken:String, success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        let params:NSDictionary = ["fb_access_token":accessToken]
        let path = "auth/facebook"
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"GET", params:nil!, success: { (result:AnyObject!) -> Void in
            self.saveLoginInfomation(result)
            success()
        }, failure:failure)!
    }
    
    class func signInViaFacebook(accessToken:String, error:NSErrorPointer) {
        signUpViaFacebook(accessToken, error:error)
    }
    
    class func signInViaFacebookInBackground(accessToken:String, success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        return signUpViaFacebookInbackground(accessToken, success:success, failure:failure)
    }
    
    class func signUpViaKakao(accessToken:String, error:NSErrorPointer) {
        let params:NSDictionary = ["kkt_access_token":accessToken]
        let path = "auth/kakaotalk"
        var result:AnyObject = BaasioNetworkManager.sharedInstance().connectWithHTTPSync(path, method:"GET", params:params, error:error)
        saveLoginInfomation(result)
    }
    
    class func signUpViaKakaoInBackground(accessToken:String, success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        let params:NSDictionary = ["kkt_access_token":accessToken]
        let path = "auth/kakaotalk"
        return BaasioNetworkManager.sharedInstance().connectWithHTTP(path, method:"GET", params:nil!, success: { (result:AnyObject!) -> Void in
            self.saveLoginInfomation(result)
            success()
            }, failure:failure)!
    }
    
    class func signInViaKakao(accessToken:String, error:NSErrorPointer) {
        signUpViaKakao(accessToken, error: error)
    }
    
    class func signInViaKakaoInBackground(accessToken:String, success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation {
        return signUpViaKakaoInBackground(accessToken, success:success, failure:failure)
    }
    
    //username 중복으로 getUsername으로 변경
    func getUsername() -> String {
        return objectForKey("username") as String
    }
    
    func setUsername(username:String) {
        setObject(username, forKey: "username")
    }
}
