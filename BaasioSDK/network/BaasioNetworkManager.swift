//
//  BaasioNetworkManager.swift
//  baas.io-sdk-ios-swift
//
//  Created by kimkkikki on 2014. 6. 10..
//  Copyright (c) 2014년 baas.io. All rights reserved.
//

import Foundation

protocol BaasioErrorDelegate {
    func hook(error:NSError)
}

class BaasioNetworkManager: NSObject {
    var delegate:BaasioErrorDelegate?
    
    class func sharedInstance() -> BaasioNetworkManager! {
        struct Static {
            static var token : dispatch_once_t = 0
            static var instance : BaasioNetworkManager? = nil
        }
        
        dispatch_once(&Static.token) { Static.instance = BaasioNetworkManager() };
        return Static.instance!
    }
    
    func connectWithHTTP(path:String, method:String, params:NSDictionary?, success:(AnyObject) -> (Void), failure:(NSError) -> (Void)) -> NSOperation? {
        logging(path, method: method, params: params)
        
        var baseURL = Baasio.sharedInstance().getAPIURL()
        var manager:AFHTTPRequestOperationManager = AFHTTPRequestOperationManager()
        manager.responseSerializer = AFJSONResponseSerializer()
        
        var parameters:NSDictionary?
        if method == "GET" || method == "DELETE" {
            parameters = params
        }
        
        var error:NSError?
        var request:NSMutableURLRequest = manager.requestSerializer.requestWithMethod(method, URLString:"\(baseURL)/\(path)", parameters:parameters, error:&error)
        
        if error != nil {
            failure(error!)
            return nil
        }
        
        request = Baasio.sharedInstance().setAuthorization(request)
        
        if method == "POST" || method == "PUT" {
            if params != nil {
                var data:NSData = NSJSONSerialization.dataWithJSONObject(params, options:NSJSONWritingOptions.PrettyPrinted, error:&error)
                
                if error != nil {
                    failure(error!)
                    return nil
                }
                
                request.HTTPBody = data
            }
        }
        
        var operation:AFHTTPRequestOperation = manager.HTTPRequestOperationWithRequest(request,
            success: { (operation:AFHTTPRequestOperation!, responseObject:AnyObject!) in
                NetworkActivityIndicatorManager.sharedInstance().hide()
                success(responseObject)
            },
            failure: { (operation:AFHTTPRequestOperation!, error: NSError!) in
                NetworkActivityIndicatorManager.sharedInstance().hide()
                failure(error)
            })
        
        operation.start()
        NetworkActivityIndicatorManager.sharedInstance().show()
        
        return operation
    }
    
    func connectWithHTTPSync(path: String, method: String, params:NSDictionary?, error:NSErrorPointer) -> AnyObject? {
        logging(path, method: method, params: params)
        var response:AnyObject?
        var isFinish:Bool = false
        var blockError:NSError?
        
        var request:NSOperation = connectWithHTTP(path, method:method, params:params,
            success: { (result:AnyObject!) in
                response = result
                isFinish = true
            },
            failure: { (error:NSError!) in
                blockError = error
                isFinish = true
            })!
        
        request.waitUntilFinished()
        
        if error != nil {
            error.memory = blockError
        }
        
        return response
    }
    
    func multipartFormRequest(path:String, method:String, bodyData:NSData, params:NSDictionary, filename:String, contentType:String?, success:(BaasioFile) -> (Void), failure:(NSError) -> (Void), progress:(Float) -> (Void)) -> AFHTTPRequestOperation {
        fileLogging(path, httpMethod: method, bodyData: bodyData, params: params, filename: filename, contentType: contentType)
        
        var url:NSURL = Baasio.sharedInstance().getAPIURL()
        var manager:AFHTTPRequestOperationManager = AFHTTPRequestOperationManager()
        manager.requestSerializer = AFHTTPRequestSerializer()
        
        var error:NSError?
        var request:NSMutableURLRequest = manager.requestSerializer.multipartFormRequestWithMethod(method, URLString:"\(url)/\(path)", parameters:nil,
            constructingBodyWithBlock: {
                (formData:AFMultipartFormData!) in
                var mutableParams:NSMutableDictionary = NSMutableDictionary(dictionary: params)
                if bodyData != nil {
                    var _contentType:NSString? = contentType
                    if _contentType == nil || _contentType == "" {
                        _contentType = self.mimeTypeForFileAtPath(filename)
                        mutableParams.setObject(_contentType, forKey:"content-type")
                    }
                    
                    formData.appendPartWithFileData(bodyData, name:"file", fileName:filename, mimeType:_contentType)

                    var error:NSError?
                    var data:NSData = NSJSONSerialization.dataWithJSONObject(mutableParams, options:NSJSONWritingOptions.PrettyPrinted, error:&error)
                    
                    formData.appendPartWithFileData(data, name:"entity", fileName:"entity", mimeType:"application/json")
                }
            }, error:&error)
        
        request = Baasio.sharedInstance().setAuthorization(request)
        
        var failureClosure = self.failure(failure)
        
        manager.responseSerializer = AFJSONResponseSerializer()
        var operation:AFHTTPRequestOperation = manager.HTTPRequestOperationWithRequest(request,
            success: { (operation:AFHTTPRequestOperation!, responseObject:AnyObject!) in
                NetworkActivityIndicatorManager.sharedInstance().hide()
                
                var dictionary:NSDictionary = responseObject as NSDictionary
                var array = dictionary["entities"] as NSArray
                var entities:NSDictionary = array[0] as NSDictionary
                
                var file:BaasioFile = BaasioFile()
                file.set(entities)
                
                success(file)
            },
            failure: { (operation:AFHTTPRequestOperation!, error: NSError!) in
                NetworkActivityIndicatorManager.sharedInstance().hide()
                failure(error)
            })
        
        operation.setUploadProgressBlock({
            (bytesWritten:Int, totalBytesWritten:CLongLong, totalBytesExpectedToWrite:CLongLong) in
                let progressNum = totalBytesWritten / totalBytesExpectedToWrite
                progress(Float(progressNum))
            })
        
        operation.start()
        NetworkActivityIndicatorManager.sharedInstance().show()
        
        return operation
    }
    
// MARK: - API response method

    func failure(failure:(NSError) -> (Void)) -> ((NSURLRequest, NSHTTPURLResponse, NSError, AnyObject) -> Void) {
        var failureClosure = {
            (request:NSURLRequest, response:NSHTTPURLResponse, error:NSError, JSON:AnyObject) -> Void in
            NetworkActivityIndicatorManager.sharedInstance().hide()
            
            var e:NSError = self.extractNormalError(error, JSON:JSON as NSDictionary)
            self.delegate?.hook(e)
            failure(e)
        }
        
        return failureClosure
    }
    
    func extractNormalError(error:NSError, JSON:NSDictionary) -> NSError {
        if JSON == nil {
            var debugDescription:AnyObject? = error.userInfo["NSDebugDescription"]
            if debugDescription != nil {
                var details:NSMutableDictionary = NSMutableDictionary()
                details.setValue(debugDescription as String, forKey:NSLocalizedDescriptionKey)
                
                var e:NSError = NSError.errorWithDomain(error.domain, code:error.code, userInfo:details)
                return e
            }
            return error
        }
        
        var message : AnyObject! = JSON["error_description"]
        var details:NSMutableDictionary = NSMutableDictionary()
        details.setValue(message as String, forKey:NSLocalizedDescriptionKey)
        
        var error_code : AnyObject! = JSON["error_code"]
        var e:NSError = NSError.errorWithDomain("BaasioError", code:error_code as Int, userInfo:details)
        return e
    }
    
    func mimeTypeForFileAtPath(path:NSString) -> String {
        var pathExtension:NSString = path.pathExtension
        var UTI:Unmanaged<CFString> = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)
        var mimeType = UTTypeCopyPreferredTagWithClass(UTI.takeRetainedValue(), kUTTagClassMIMEType)
        UTI.release()
        if !mimeType {
            return "application/octet-stream"
        }
        return CFBridgingRelease(mimeType) as String
    }
    
    func fileLogging(path:String, httpMethod:String, bodyData:NSData, params:NSDictionary, filename:String, contentType:String?) {
        if Baasio.sharedInstance().isDebugMode() {
            let urlPrefix = Baasio.sharedInstance().getAPIURL().absoluteString
            
            println("- Start ---------------------------------------------------------------------------")
            println("url : \(urlPrefix)/\(path)")
            println("method : \(httpMethod)")
            println("params : \(params.description)")
            println("filename : \(filename)")
            println("contentType : \(contentType)")
            println("body : \(bodyData.description)")
            println("-----------------------------------------------------------------------------------")
        }
    }
    
    func logging(path:String, method:String, params:NSDictionary?) {
        if Baasio.sharedInstance().isDebugMode() {
            var urlPrefix:String = Baasio.sharedInstance().getAPIURL().absoluteString
            println("- Start - -------------------------------------------------------------------------")
            println("url : \(urlPrefix)/\(path)")
            println("method : \(method)")
            println("params : \(params.description)");
            println("-----------------------------------------------------------------------------------")
        }
    }
}