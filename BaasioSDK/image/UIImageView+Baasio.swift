//
//  UIImageView+Baasio.swift
//  baas.io-sdk-ios-swift
//
//  Created by kimkkikki on 2014. 6. 17..
//  Copyright (c) 2014년 baas.io. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView {
    func imageWithURL(url:NSURL) {
        self.setImageWithURL(url)
    }
    
    func imageWithURL(url:NSURL, placeholderImage:UIImage) {
        self.setImageWithURL(url, placeholderImage:placeholderImage)
    }
    
    func imageWithURLRequest(urlRequest:NSURLRequest, placeholderImage:UIImage, success:(NSURLRequest!, NSHTTPURLResponse!, UIImage!) -> (Void), failure:(NSURLRequest!, NSHTTPURLResponse!, NSError!) -> (Void)) {
        self.setImageWithURLRequest(urlRequest, placeholderImage:placeholderImage, success:success, failure:failure)
    }
    
    func imageWithBaasioFile(file:BaasioFile) {
        self.imageWithURL(file.url!)
    }
    
    func imageWithBaasioFile(file:BaasioFile, placeholderImage:UIImage) {
        self.imageWithURL(file.url!, placeholderImage:placeholderImage)
    }
    
    func cancelImageRequest() {
        self.cancelImageRequestOperation()
    }
}