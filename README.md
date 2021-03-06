# ChangeKit
A Changetip Library for iOS

This library simplifies using the Changetip API for iOS. It's written in Swift 2.0 for iOS 8 and above.

### Installation

1. First, install the following CocoaPods:

  * AFNetworking (I'm using version 2.6.0)
  * AFOAuth2Manager (I'm using version 2.2.0)
  
2. Add the ChangeKit folder to your project.

3. Add the file "ChangeKitBridgingHeader.h" as the bridging header for your app and any extensions (Targets -> your app -> Build Settings -> Objective C Bridging Header). Note that you may need to mention its enclosing folder.

4. Add the following function to your app delegate. This will allow the app to notify ChangeKit when a user logs in with Changetip.

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

5. Add the following to your app's info.plist, replacing YOUR_APP_BUNDLE_ID with your bundle id, i.e. "com.cablej.ChangetipApp". This will allow the x-callback-url to be associated with your app.

	```
	<key>CFBundleURLTypes</key>
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

* (optional) full - Get full user information - Changetip.Me.full or Changetip.Me.notFull. Will default to not full if none is provided.

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

* (optional) currency - USD or BTC pocket - ChangeKit.Currency.btc or ChangeKit.Currency.usd. Will default to BTC if none is provided.

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
* (optional) message - A message to include with the tip. Will default to no message if none is provided.

```
ChangeKit.sharedInstance.createTipURL("$1", message: "Don't spend it all in one place!") { (response) -> Void in
    guard let response = response, let magicURL = response["magic_url"] else {
        print("Could not get information.")
        return
    }
    print(magicURL)
}
```

#### address (get the bitcoin deposit address of a changetip user)

Parameters:

* (optional)  username - The Changetip user whose address you want. Will default to the current user.

```
ChangeKit.sharedInstance.address("some_user") { (response) -> Void in
    guard let response = response else {
        print("Could not get information.")
        return
    }
    print(response)
}
```

#### monikers (get the list of monikers of the current user)

Parameters:

* (optional) page - The page of monikers to get, each page has 100 monikers. Will default to page 1.

```
ChangeKit.sharedInstance.monikers() { (response) -> Void in
    guard let response = response else {
        print("Could not get information.")
        return
    }
    print(response)
}
```

#### currencies (get the list of currencies and their values supported by Changetip)

```
ChangeKit.sharedInstance.currencies() { (response) -> Void in
    guard let response = response else {
        print("Could not get information.")
        return
    }
    print(response)
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
