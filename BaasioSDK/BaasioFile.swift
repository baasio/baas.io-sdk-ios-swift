//
//  BaasioFile.swift
//  baas.io-sdk-ios-swift
//
//  Created by kimkkikki on 2014. 6. 11..
//  Copyright (c) 2014년 baas.io. All rights reserved.
//

import Foundation

class BaasioFile: BaasioEntity {
    var filename:String? {
        get {
            return objectForKey("filename") as? String
        }
        set {
            setObject(newValue!, forKey:"filename")
        }
    }
    var contentType:String? {
        get {
            return objectForKey("content-type") as? String
        }
        set {
            setObject(newValue!, forKey:"content-type")
        }
    }
    var data:NSData?
    
    var url:NSURL? {
        if uuid == nil {
            return nil
        }
        var path:String = "\(Baasio.sharedInstance().getAPIURL())/file/\(uuid)"
        path = path.stringByReplacingOccurrencesOfString("https://api.", withString:"https://blob.")
        
        return NSURL.URLWithString(path)
    }
    
    init() {
        super.init()
        entityName = "files"
    }

    func fileDownloadInBackground(downloadPath:String, success:(String) -> (Void), failure:(NSError) -> (Void), progress:(Float) -> (Void)) -> NSOperation {
        let url = Baasio.sharedInstance().getAPIURL()
        let path = "\(url)/\(entityName)/\(uuid)/data"
        
        var error:NSError?
        
        var manager:AFHTTPRequestOperationManager = AFHTTPRequestOperationManager()
        manager.responseSerializer = AFJSONResponseSerializer()
        
        var request:NSMutableURLRequest = manager.requestSerializer.requestWithMethod("GET", URLString:path, parameters:nil, error:&error)
        request = Baasio.sharedInstance().setAuthorization(request)
        
        var failureClosure = BaasioNetworkManager.sharedInstance().failure(failure)
        
        var operation:AFHTTPRequestOperation = manager.HTTPRequestOperationWithRequest(request,
            success: { (operation:AFHTTPRequestOperation!, responseObject:AnyObject!) in
                NetworkActivityIndicatorManager.sharedInstance().hide()
                success(downloadPath)
            },
            failure: { (operation:AFHTTPRequestOperation!, error: NSError!) in
                NetworkActivityIndicatorManager.sharedInstance().hide()
                failure(error)
            })
        operation.outputStream = NSOutputStream.outputStreamToFileAtPath(downloadPath, append:false)
        operation.setDownloadProgressBlock({
            (bytesRead:Int, totalBytesRead:CLongLong, totalBytesExpectedToRead:CLongLong) in
            let progressNum = Float(totalBytesRead) / Float(totalBytesExpectedToRead)
            progress(progressNum)
            })
        operation.start()
        NetworkActivityIndicatorManager.sharedInstance().show()
        
        return operation
    }
    
    func fileUploadInBackground(success:(BaasioFile) -> (Void), failure:(NSError) -> (Void), progress:(Float) -> (Void)) -> NSOperation {
        return BaasioNetworkManager.sharedInstance().multipartFormRequest(entityName!, method:"POST", bodyData:data!, params:dictionary, filename:filename!, contentType:contentType,
            success:success, failure:failure, progress:progress)
    }
    
    func fileUpdateInBackground(success:(BaasioFile) -> (Void), failure:(NSError) -> (Void), progress:(Float) -> (Void)) -> NSOperation {
        let path:String = "\(entityName)/\(uuid)"
        return BaasioNetworkManager.sharedInstance().multipartFormRequest(path, method:"PUT", bodyData:data!, params:dictionary, filename:filename!, contentType:contentType!,
            success:success, failure:failure, progress:progress)
    }
    
    func getInBackground(success:(BaasioFile) -> (Void), failure:(NSError) -> (Void)) -> NSOperation? {
        return BaasioFile.getInBackground(entityName!, uuid:uuid!,
            success:{ (entity:BaasioEntity) in
                var file:BaasioFile = BaasioFile()
                file.set(entity.dictionary)
                success(file)
            }, failure:failure)
    }
    
    override func updateInBackground(success:(BaasioFile) -> (Void), failure:(NSError) -> (Void)) -> NSOperation? {
        return super.updateInBackground({
            (entity:BaasioEntity) in
            var file:BaasioFile = BaasioFile()
            file.set(entity.dictionary)
            success(file)
        }, failure:failure)
    }
    
    override func connect(entity:BaasioEntity, relationship:String, error:NSErrorPointer) {
        NSException.raise("BaasioUnsupportedException", format:"Don't connect in Baasiofile.", arguments:nil!)
    }
    
    override func connectInBackground(entity:BaasioEntity, relationship:String, success:(Void) -> (Void), failure:(NSError) -> (Void)) -> NSOperation? {
        NSException.raise("BaasioUnsupportedException", format:"Don't connect in Baasiofile.", arguments:nil!)
        return nil
    }
    
    func setContentType(contentType:String) {
        setObject(contentType, forKey:"content-type")
    }
    
    func setFilename(filename:String) {
        setObject(filename, forKey:"filename")
    }
}