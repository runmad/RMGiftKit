Introduction
------------
RMGiftKit is a class that you can add to any iOS app and then allow you to prompt your users to
Gift the app in the App Store. 

RMGiftKit is heavily inspired by and borrows lots of code from [Appirater] [appiraterlink]

The RMGiftKit prompt will appear in every new build version of your app.

Feel free to modify and share your changes with the world. 
Check out the #idevblogaday [blog post I wrote about RMGiftKit (formerly GiftKit)] [bloglink].

Getting Started
---------------
1. Add the RMGiftKit to your project
2. Add the `CFNetwork` and `SystemConfiguration` frameworks to your project
3. Call `[RMGiftKit appLaunched:YES]` at the end of your app delegate's `application:didFinishLaunchingWithOptions:` method.
4. Call `[RMGiftKit appEnteredForeground:YES]` in your app delegate's `applicationWillEnterForeground:` method.
5. (OPTIONAL) Call `[RMGiftKit userDidSignificantEvent:YES]` when the user does something 'significant' in the app.
6. Finally, set the `RMGIFTKIT_APP_ID` in `GiftKit.h` to your Apple provided software id.
7. (OPTIONAL) Change days/uses/alert text in `GiftKit.h` to suit your needs.
8. (OPTIONAL) Add a `Gift this app` to allow the user to Gift more times in the same version - or without having to wait for the prompt! Call `[GiftKit giftApp]` to jump directly to your App's App Store page.

License
-------
Copyright 2011 [Rune Madsen] [rune].
This library is distributed under the terms of the MIT/X11.

If you have any changed and updates to GiftKit, feel free to add them so the whole community 
can enjoy them! :)

![RMGiftKit](http://runmad.com/blog/wp-content/uploads/2011/05/GiftKitScreenshot.png)

[bloglink]: http://runmad.com/blog/2011/05/introducing-giftkit-gifting-made-easy/
[rune]: http://www.runmad.com/blog
[appiraterlink]: http://arashpayan.com/blog/index.php/2009/09/07/presenting-appirater/