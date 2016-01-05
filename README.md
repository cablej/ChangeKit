# ChangeKit
A Changetip Library for iOS

This library simplifies using the Changetip API for iOS. It's written in Swift 2.0 for iOS 8 and above.

### Installation

1. First, install the following CocoaPods:

  * AFNetworking (I'm using version 2.6.0)
  * AFOAuth2Manager (I'm using version 2.2.0)
  
2. Add the ChangeKit folder to your project.

3. Add the file "ChangeKitBridgingHeader.h" as the bridging header for your app and any extensions (Targets -> your app -> Build Settings -> Objective C Bridging Header).

4. Add the following function to your app delegate:

```

//Send a notification when the user logs in with changetip.
func application(application: UIApplication,
    openURL url: NSURL,
    sourceApplication: String?,
    annotation: AnyObject) -> Bool {
        let notification = NSNotification(
            name: "AGAppLaunchedWithURLNotification",
            object:nil,
            userInfo:[UIApplicationLaunchOptionsURLKey:url])
        NSNotificationCenter.defaultCenter().postNotification(notification)
        return true
}
    
```

This will allow the app to notify ChangeKit when a user logs in with Changetip.

5. Add to your app's info.plist, replacing YOUR_APP_BUNDLE_ID with your bundle id, i.e. "com.cablej.ChangetipApp"

```
<array>
		<dict>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>YOUR_APP_BUNDLE_ID</string>
			</array>
		</dict>
	</array>
```

### Authentication

Authentication is easy and straightfoward. OAuth tokens are stored in the keychain.

We run into one problem with the API. We want the callback url to be an x-callback-url, which will open in the app. However, Changetip's API currently does not allow this. You want your app's redirect uri to be of the form:

```
YOUR_APP_BUNDLE_ID:/oauth2Callback?
```

As a temporary workaround, we must have an intermediate server to redirect here. You can either use your own, or use the server I have graciously provided:

```
http://tiphound.me/callback.php?u=YOUR_APP_BUNDLE_ID
```

First, initialize your client id, client secret, and scope, obtained from [Changetip's API](https://www.changetip.com/o/applications/).

```
ChangeKit.sharedInstance.clientID = "your_client_id"
ChangeKit.sharedInstance.clientSecret = "your_client_secret"
ChangeKit.sharedInstance.redirect_uri = "your_redirect_uri"
```

Next, declare your Changetip scope. Note that you must also configure this on the Changetip API for your application. The full list of API scopes is available [here](https://www.changetip.com/api/auth/).
```
ChangeKit.sharedInstance.scope = ["create_tip_urls", "read_user_basic"]
```

Now, you can authenticate a user: 

```
ChangeKitAuthenticate.sharedInstance.authenticate()
```

This will open a safari tab prompting the user to log in with Changetip. ChangeKit handles all other aspects of logging in.

### Making API Requests

All API endpoints return an optional Swift Dictionary with the Changetip response, or nil (if an error occurred).

#### me (information about current user)

Parameters:

* full - Get full user information - Changetip.Me.full or Changetip.Me.full

```
ChangeKit.sharedInstance.me(ChangeKit.Me.full) { (response) -> Void in
    guard let response = response else {
        print("Could not get information.")
        return
    }
    print(response)
}

//["hide_profile_data": 0, "uuid": ... ]
```

#### balance (current balance)

Parameters:

* currency - USD or BTC pocket - ChangeKit.Currency.btc or ChangeKit.Currency.usd

```
ChangeKit.sharedInstance.balance(ChangeKit.Currency.btc) { (response) -> Void in
    guard let response = response, let balance = response["balance_user_currency"] else {
        print("Could not get information.")
        return
    }
    print(balance)
}
```

#### tip-url (create a one-time tip url)

Parameters:

* amount - amount to send. Changetip will parse this, so it can be in any form.
* message - A message to include with the tip.

```
ChangeKit.sharedInstance.createTipURL("$1", message: "Don't spend it all in one place!") { (response) -> Void in
    guard let response = response, let magicURL = response["magic_url"] else {
        print("Could not get information.")
        return
    }
    print(magicURL)
}
```

#### Other API Requests

I'm working on adding all endpoints to the library. For now, to make other requests, use ChangeKit.sharedInstance.request:

```
ChangeKit.sharedInstance.request("v2/tip-url", method: "POST", parameters: ["amount" : amount, "message": message]) { (response) -> Void in
    guard let response = response, let magicURL = response["magic_url"] else {
        print("Could not get information.")
        return
    }
    print(magicURL)
}
```

#### Support

I'm happy to help with any issues you might have, and feel free to contribute to this project!
