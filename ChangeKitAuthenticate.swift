//
//  ChangeKitAuthenticate.swift
//  ChangetipKeyboard
//
//  Created by Jack Cable on 1/3/16.
//  Copyright © 2016 Jack Cable. All rights reserved.
//

import UIKit
import MobileCoreServices
import AssetsLibrary

class ChangeKitAuthenticate: NSObject {
    static let sharedInstance = ChangeKitAuthenticate()

    var isObserved = false
    func authenticate() {
        // 1 Replace with client id /secret
        
        if !isObserved {
            // 2 Add observer
            NSNotificationCenter.defaultCenter().addObserverForName(
                "AGAppLaunchedWithURLNotification",
                object: nil,
                queue: nil,
                usingBlock: { (notification: NSNotification!) -> Void in
                    // [5] extract code
                    let code = self.extractCode(notification)
                    
                    // [6] carry on oauth2 code auth grant flow with AFOAuth2Manager
                    let manager = AFOAuth2Manager(baseURL: ChangeKit.sharedInstance.baseURL,
                        clientID: ChangeKit.sharedInstance.clientID,
                        secret: ChangeKit.sharedInstance.clientSecret)
                    manager.useHTTPBasicAuthentication = false
                    
                    // [7] exchange authorization code for access token
                    manager.authenticateUsingOAuthWithURLString("o/token/",
                        code: code,
                        redirectURI: ChangeKit.sharedInstance.redirect_uri,
                        success: { (cred: AFOAuthCredential!) -> Void in
                            
                            let keychain = Keychain()
                            
                            keychain["accessToken"] = cred.accessToken
                            
                        }) { (error: NSError!) -> Void in
                            print("Error: \(error!.localizedDescription)")
                    }
            })
            isObserved = true
        }
        
        let scopeString = ChangeKit.sharedInstance.scope.joinWithSeparator("%20")
        
        // 3 calculate final url
        let params = "?scope=\(scopeString)&redirect_uri=\(ChangeKit.sharedInstance.redirect_uri)&client_id=\(ChangeKit.sharedInstance.clientID)&response_type=code"
        // 4 open an external browser
        UIApplication.sharedApplication().openURL(NSURL(string: "https://changetip.com/o/authorize/\(params)")!)
    }
    
    func extractCode(notification: NSNotification) -> String? {
        let url: NSURL? = (notification.userInfo as!
            [String: AnyObject])[UIApplicationLaunchOptionsURLKey] as? NSURL
        
        // [1] extract the code from the URL
        return self.parametersFromQueryString(url?.query)["code"]
    }
    
    func parametersFromQueryString(queryString: String?) -> [String: String] { //helper method for oauth
        var parameters = [String: String]()
        if (queryString != nil) {
            var parameterScanner: NSScanner = NSScanner(string: queryString!)
            var name:NSString? = nil
            var value:NSString? = nil
            while (parameterScanner.atEnd != true) {
                name = nil
                parameterScanner.scanUpToString("=", intoString: &name)
                parameterScanner.scanString("=", intoString:nil)
                value = nil
                parameterScanner.scanUpToString("&", intoString:&value)
                parameterScanner.scanString("&", intoString:nil)
                if (name != nil && value != nil) {
                    parameters[name!.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!]
                        = value!.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
                }
            }
        }
        return parameters
    }
}
