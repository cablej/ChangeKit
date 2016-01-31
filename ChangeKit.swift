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
    var redirect_uri = ""
    
    let baseURL = NSURL(string: "https://www.changetip.com/")
    
    let keychain = Keychain()
    
    struct Currency {
        static let btc = "btc"
        static let usd = "usd"
    }
    
    struct Me {
        static let full = "full"
        static let notFull = ""
    }
    
    private override init() {
        super.init()
    }
    
    func request(endpoint: String, method: String, parameters: [String: String]?, completionHandler: ([String:AnyObject]?) -> Void) {
        guard let accessToken = keychain["accessToken"] else {
            completionHandler(nil)
            return
        }
        
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
            //print(error)
            guard let data = data, let dataString = String.init(data: data, encoding: NSUTF8StringEncoding), let jsonDict = self.convertStringToDictionary(dataString) else {
                completionHandler(nil)
                return
            }
            
            completionHandler(jsonDict)
        }
    }
    
    //Create a one time tip url with the specified parameters.
    func tipURL(amount: String, message: String = "", completionHandler: ([String:AnyObject]?) -> Void){
        request("v2/tip-url", method: "POST", parameters: ["amount" : amount, "message": message]) { (response) -> Void in
            completionHandler(response)
        }
    }
    
    //Get the information of the current user.
    func me(full: String = "", completionHandler: ([String:AnyObject]?) -> Void) {
        request("v2/me", method: "GET", parameters: ["full" : full]) { (response) -> Void in
            completionHandler(response)
        }
    }
    
    //Get the balance of the current user.
    func balance(currency: String = Currency.btc, completionHandler: ([String:AnyObject]?) -> Void) {
        request("v2/pocket/\(currency)/balance", method: "GET", parameters: nil) { (response) -> Void in
            completionHandler(response)
        }
    }
    
    //Get the bitcoin wallet address of the specified user, or the current user if none is specified.
    func address(username: String = "", completionHandler: ([String:AnyObject]?) -> Void) {
        request("v2/wallet/address", method: "GET", parameters: ["username" : username]) { (response) -> Void in
            completionHandler(response)
        }
    }
    
    //Get the monikers for the current user.
    func monikers(page: Int = 1, completionHandler: ([String:AnyObject]?) -> Void) {
        request("v2/monikers", method: "GET", parameters: ["page" : String(page)]) { (response) -> Void in
            completionHandler(response)
        }
    }
    
    //Get the currencies and their values supported by Changetip.
    func currencies(completionHandler: ([String:AnyObject]?) -> Void) {
        request("v2/currencies", method: "GET", parameters: nil) { (response) -> Void in
            completionHandler(response)
        }
    }
    
    //Get the transactions history of a user
    func transactions(channel: String, completionHandler: ([String:AnyObject]?) -> Void) {
        request("v2/transactions/", method: "GET", parameters: ["channel": channel]) { (response) -> Void in
            completionHandler(response)
        }
    }
    
    //Initiate a withdrawal, amount in BTC
    func withdraw(amount: String, address: String, completionHandler: ([String:AnyObject]?) -> Void) {
        request("v2/pocket/withdrawals/", method: "POST", parameters: ["amount": amount, "address": address]) { (response) -> Void in
            completionHandler(response)
        }
    }
    
    //Send a tip to another user
    func tip(receiver: String, message: String, channel: String, completionHandler: ([String:AnyObject]?) -> Void) {
        request("v2/tip/", method: "POST", parameters: ["receiver": receiver, "message": message, "channel": channel]) { (response) -> Void in
            completionHandler(response)
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
