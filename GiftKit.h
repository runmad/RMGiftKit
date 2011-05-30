/*
 This file is part of GiftKit.
 
 Copyright (c) 2011, Rune Madsen
 All rights reserved.
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */

/*
 * GiftKit.h
 * GiftKit
 *
 * Created by Rune Madsen on 29/5/11.
 * http://www.runmad.com/blog/
 * Copyright 2011 Rune Madsen / The App Boutique. All rights reserved.
 *
 * GiftKit is heavily inspired by and borrows lots of code from Appirater
 * Get it here: https://github.com/arashpayan/appirater/
 * Created by Arash Payan on 9/5/09.
 * http://arashpayan.com
 * Copyright 2010 Arash Payan. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

extern NSString *const kGiftKitFirstUseDate;
extern NSString *const kGiftKitUseCount;
extern NSString *const kGiftKitSignificantEventCount;
extern NSString *const kGiftKitCurrentVersion;
extern NSString *const kGiftKitGiftedCurrentVersion;
extern NSString *const kGiftKitDeclinedToGift;

/* 
// Place your Apple generated software id here. 
*/
#define GIFTKIT_APP_ID						416325094

/*
// Your app's name. Uses the Bundle display name by default.
*/
#define GIFTKIT_APP_NAME					[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey]

/*
// This is the message your users will see once they've passed the day+launches threshold.
*/
#define GIFTKIT_MESSAGE						[NSString stringWithFormat:@"Share %@ with a friend! Gift %@ through the App Store. Simply scroll to the bottom and tap \"Gift This App\"\nThanks for your support!", GIFTKIT_APP_NAME, GIFTKIT_APP_NAME]

/*
// This is the title of the gifting alert that users will see.
*/
#define GIFTKIT_MESSAGE_TITLE				[NSString stringWithFormat:@"Gift %@", GIFTKIT_APP_NAME]

/*
// The text for the button to dismiss (and never see the alert again until next version) the gifting alert.
*/
#define GIFTKIT_CANCEL_BUTTON				@"No, Thanks"

/*
// The text for the button that will send user the App Store where they will be able to Gift the app.
*/
#define GIFTKIT_GIFT_BUTTON					[NSString stringWithFormat:@"Gift %@", GIFTKIT_APP_NAME]

/*
// The text for the button to remind the user to gift it at a later time.
// Use GIFTKIT_TIME_BEFORE_REMINDING below to set number of days until next prompt.
*/
#define GIFTKIT_GIFT_LATER					@"Remind me later"

/*
// Users will need to have the same version of your app installed for this many
// days before they will be prompted to gift the app.
*/
#define GIFTKIT_DAYS_UNTIL_PROMPT			5		// double

/*
// An example of a 'use' would be if the user launched the app. Bringing the app
// into the foreground (on devices that support it) would also be considered
// a 'use'. You tell GiftKit about these events using the two methods:
// [GiftKit appLaunched:]
// [GiftKit appEnteredForeground:]
 
// Users need to 'use' the same version of the app this many times before
// before they will be prompted to gift it.
*/
#define GIFTKIT_USES_UNTIL_PROMPT			15		// integer

/*
// A significant event can be anything you want to be in your app. In a
// telephone app, a significant event might be placing or receiving a call.
// In a game, it might be beating a level or a boss. This is just another
// layer of filtering that can be used to make sure that only the most
// loyal of your users are being prompted to gift the app.
// If you leave this at a value of -1, then this won't be a criteria
// used for rating. To tell GiftKit that the user has performed
// a significant event, call the method:
// [GiftKit userDidSignificantEvent:];
*/
#define GIFTKIT_SIG_EVENTS_UNTIL_PROMPT		25	// integer

/*
// Once the rating alert is presented to the user, they might select
// 'Remind me later'. This value specifies how long (in days) GiftKit
// will wait before reminding them to gift the app.
*/
#define GIFTKIT_TIME_BEFORE_REMINDING		2	// double

/*
// 'YES' will show the GiftKit alert everytime. Useful for testing how your message
// looks and making sure the link to your app in the App Store works.
*/
#define GIFTKIT_DEBUG						YES

@interface GiftKit : NSObject <UIAlertViewDelegate> {
	UIAlertView	*giftingAlert;
}

@property(nonatomic, retain) UIAlertView *giftingAlert;

/*
// DEPRECATED: While still functional, it's better to use
// appLaunched:(BOOL)canPromptForRating instead.
// 
// Calls [GiftKit appLaunched:YES]. See appLaunched: for details of functionality.
*/
+ (void)appLaunched;

/*
// Tells GiftKit that the app has launched, and on devices that do NOT
// support multitasking, the 'uses' count will be incremented. You should
// call this method at the end of your application delegate's
// application:didFinishLaunchingWithOptions: method.
// 
// If the app has been used enough to prompt the user to gift the app 
// (and enough significant events), you can suppress the gifting alert
// by passing NO for canPromptForRating. The gifting alert will simply be postponed
// until it is called again with YES for canPromptForRating. The gifting alert
// can also be triggered by appEnteredForeground: and userDidSignificantEvent:
// (as long as you pass YES for canPromptForRating in those methods).
*/
+ (void)appLaunched:(BOOL)canPromptForRating;

/*
// Tells GiftKit that the app was brought to the foreground on multitasking
// devices. You should call this method from the application delegate's
// applicationWillEnterForeground: method.
// 
// If the app has been used enough to be prompt the user to gift the app
// (and enough significant events), you can suppress the gifting alert
// by passing NO for canPromptForRating. The gifting alert will simply be postponed
// until it is called again with YES for canPromptForRating. The gifting alert
// can also be triggered by appLaunched: and userDidSignificantEvent:
// (as long as you pass YES for canPromptForRating in those methods).
// */
+ (void)appEnteredForeground:(BOOL)canPromptForRating;

/*
// Tells GiftKit that the user performed a significant event. A significant
// event is whatever you want it to be. If you're app is used to make VoIP
// calls, then you might want to call this method whenever the user places
// a call. If it's a game, you might want to call this whenever the user
// beats a level boss.
// 
// If the user has performed enough significant events and used the app enough,
// you can suppress the gifting alert by passing NO for canPromptForRating. The
// rating alert will simply be postponed until it is called again with YES for
// canPromptForRating. The gifting alert can also be triggered by appLaunched:
// and appEnteredForeground: (as long as you pass YES for canPromptForRating
// in those methods).
*/
+ (void)userDidSignificantEvent:(BOOL)canPromptForRating;

/*
// Tells GiftKit to open the App Store page for the app
// GiftKit also records the fact that this has happened, so the
// user won't be prompted again to gift the app (before next version).
//
// The only case where you should call this directly is if your app has an
// explicit "Gift this app" command somewhere.  In all other cases, don't worry
// about calling this -- instead, just call the other functions listed above,
// and let GiftKit handle the bookkeeping of deciding when to ask the user
// whether to gift the app.
//
// See my blog post on Gifting: http://runmad.com/blog/2011/04/assisted-word-of-mouth-get-users-to-sell-your-app/
// Add a place in your Settings (or game menu screen) where the user can gift the app.
// Since the alert will only show once per version (unless "Remind me later" is tapped)
// adding this in your app and calling giftApp: explicitly when the user taps the button
// will allow the user to gift the app to more than one friend (without manually finding
// your app in the App Store).
*/
+ (void)giftApp;

@end