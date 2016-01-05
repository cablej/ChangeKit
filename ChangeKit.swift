//
//  ChangeKit.swift
//  ChangetipKeyboard
//
//  Created by Jack Cable on 1/3/16.
//  Copyright © 2016 Jack Cable. All rights reserved.
//

import UIKit
import MobileCoreServices
import AssetsLibrary

public class ChangeKit: NSObject {
    static let sharedInstance = ChangeKit()
    
    var clientID = ""
    var clientSecret = ""
    var scope: [String] = []
    let redirect_uri = "http://tiphound.me/callback.php"
    
    let baseURL = NSURL(string: "https://www.changetip.com/")
    
    let keychain = Keychain()
    
    struct Currency {
        static let btc = "btc"
        static let usd = "usd"
    }
    
    private override init() {
        print("booting up...")
        super.init()
    }
    
    func request(endpoint: String, method: String, parameters: [String: String]?, completionHandler: ([String:AnyObject]?) -> Void) {
        guard let accessToken = keychain["accessToken"] else {
            completionHandler(nil)
            return
        }
        
        print("access token: \(accessToken)")
        
        
        var url = "https://www.changetip.com/\(endpoint)"
        
        if method == "GET" && parameters != nil {
            url += "?" + parameters!.stringFromHttpParameters()
        }
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        if method == "POST" && parameters != nil {
            request.HTTPBody = parameters!.stringFromHttpParameters().dataUsingEncoding(NSUTF8StringEncoding)
        }
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response, data, error) -> Void in
            print(error)
            guard let data = data, let dataString = String.init(data: data, encoding: NSUTF8StringEncoding), let jsonDict = self.convertStringToDictionary(dataString) else {
                completionHandler(nil)
                return
            }
            
            completionHandler(jsonDict)
        }
    }
    
    func tipURL(amount: String, message: String, completionHandler: ([String:AnyObject]?) -> Void){
        request("v2/tip-url", method: "POST", parameters: ["amount" : amount, "message": message]) { (dictionary) -> Void in
            completionHandler(dictionary)
        }
    }
    
    func me(full: Bool, completionHandler: ([String:AnyObject]?) -> Void) {
        request("v2/me", method: "GET", parameters: ["full" : String(full)]) { (dictionary) -> Void in
            completionHandler(dictionary)
        }
    }
    
    func balance(currency: String, completionHandler: ([String:AnyObject]?) -> Void) {
        request("v2/pocket/\(currency)/balance", method: "GET", parameters: nil) { (dictionary) -> Void in
            completionHandler(dictionary)
        }
    }
    
    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:AnyObject]
                return json
            } catch {
                print("Something went wrong")
            }
        }
        return nil
    }

}

extension String { //helper method for oauth
    public func urlEncode() -> String {
        let encodedURL = CFURLCreateStringByAddingPercentEscapes(
            nil,
            self as NSString,
            nil,
            "!@#$%&*'();:=+,/?[]",
            CFStringBuiltInEncodings.UTF8.rawValue)
        return encodedURL as String
    }
}

extension Dictionary {
    func stringFromHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            let percentEscapedKey = (key as! String).urlEncode()
            let percentEscapedValue = (value as! String).urlEncode()
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        
        return parameterArray.joinWithSeparator("&")
    }
}
