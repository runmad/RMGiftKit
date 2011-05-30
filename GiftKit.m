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
 * GiftKit is inspired by and lends lots of code from Appirater
 * Get it here: https://github.com/arashpayan/appirater/
 * Created by Arash Payan on 9/5/09.
 * http://arashpayan.com
 * Copyright 2010 Arash Payan. All rights reserved.
 *
 */


#import "GiftKit.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>

NSString *const kGiftKitFirstUseDate				= @"kGiftKitFirstUseDate";
NSString *const kGiftKitUseCount					= @"kGiftKitUseCount";
NSString *const kGiftKitSignificantEventCount		= @"kGiftKitSignificantEventCount";
NSString *const kGiftKitCurrentVersion				= @"kGiftKitCurrentVersion";
NSString *const kGiftKitGiftedCurrentVersion		= @"kGiftKitGiftedCurrentVersion";
NSString *const kGiftKitDeclinedToGift				= @"kGiftKitDeclinedToGift";
NSString *const kGiftKitReminderRequestDate			= @"kGiftKitReminderRequestDate";

NSString *templateGiftURL = @"http://itunes.apple.com/app/next-ttc/idAPP_ID?mt=8";

@interface GiftKit (hidden)
- (BOOL)connectedToNetwork;
+ (GiftKit*)sharedInstance;
- (void)showGiftingAlert;
- (BOOL)ratingConditionsHaveBeenMet;
- (void)incrementUseCount;
@end

@implementation GiftKit (hidden)

- (BOOL)connectedToNetwork {
    // Create zero addy
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
	
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
	
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
	
    if (!didRetrieveFlags)
    {
        NSLog(@"Error. Could not recover network reachability flags");
        return NO;
    }
	
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
	BOOL nonWiFi = flags & kSCNetworkReachabilityFlagsTransientConnection;
	
	NSURL *testURL = [NSURL URLWithString:@"http://www.apple.com/"];
	NSURLRequest *testRequest = [NSURLRequest requestWithURL:testURL  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
	NSURLConnection *testConnection = [[NSURLConnection alloc] initWithRequest:testRequest delegate:self];
	
    return ((isReachable && !needsConnection) || nonWiFi) ? (testConnection ? YES : NO) : NO;
}

+ (GiftKit*)sharedInstance {
	static GiftKit *giftkit = nil;
	if (giftkit == nil)
	{
		@synchronized(self) {
			if (giftkit == nil) {
				giftkit = [[GiftKit alloc] init];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:@"UIApplicationWillResignActiveNotification" object:nil];
            }
        }
	}
	return giftkit;
}

- (void)showGiftingAlert {
	UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:GIFTKIT_MESSAGE_TITLE
														 message:GIFTKIT_MESSAGE
														delegate:self
											   cancelButtonTitle:GIFTKIT_CANCEL_BUTTON
											   otherButtonTitles:GIFTKIT_GIFT_BUTTON, GIFTKIT_GIFT_LATER, nil] autorelease];
	self.giftingAlert = alertView;
	[alertView show];
}

- (BOOL)ratingConditionsHaveBeenMet {
	if (GIFTKIT_DEBUG)
		return YES;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSDate *dateOfFirstLaunch = [NSDate dateWithTimeIntervalSince1970:[userDefaults doubleForKey:kGiftKitFirstUseDate]];
	NSTimeInterval timeSinceFirstLaunch = [[NSDate date] timeIntervalSinceDate:dateOfFirstLaunch];
	NSTimeInterval timeUntilGifting = 60 * 60 * 24 * GIFTKIT_DAYS_UNTIL_PROMPT;
	if (timeSinceFirstLaunch < timeUntilGifting)
		return NO;
	
	// check if the app has been used enough
	int useCount = [userDefaults integerForKey:kGiftKitUseCount];
	if (useCount <= GIFTKIT_USES_UNTIL_PROMPT)
		return NO;
	
	// check if the user has done enough significant events
	int sigEventCount = [userDefaults integerForKey:kGiftKitSignificantEventCount];
	if (sigEventCount <= GIFTKIT_SIG_EVENTS_UNTIL_PROMPT)
		return NO;
	
	// has the user previously declined to gift this version of the app?
	if ([userDefaults boolForKey:kGiftKitDeclinedToGift])
		return NO;
	
	// has the user already gifted the app?
	if ([userDefaults boolForKey:kGiftKitGiftedCurrentVersion])
		return NO;
	
	// if the user wanted to be reminded later, has enough time passed?
	NSDate *reminderRequestDate = [NSDate dateWithTimeIntervalSince1970:[userDefaults doubleForKey:kGiftKitReminderRequestDate]];
	NSTimeInterval timeSinceReminderRequest = [[NSDate date] timeIntervalSinceDate:reminderRequestDate];
	NSTimeInterval timeUntilReminder = 60 * 60 * 24 * GIFTKIT_TIME_BEFORE_REMINDING;
	if (timeSinceReminderRequest < timeUntilReminder)
		return NO;
	
	return YES;
}

- (void)incrementUseCount {
	// get the app's version
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
	
	// get the version number that we've been tracking
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *trackingVersion = [userDefaults stringForKey:kGiftKitCurrentVersion];
	if (trackingVersion == nil)
	{
		trackingVersion = version;
		[userDefaults setObject:version forKey:kGiftKitCurrentVersion];
	}
	
	if (GIFTKIT_DEBUG)
		NSLog(@"GIFTKIT Tracking version: %@", trackingVersion);
	
	if ([trackingVersion isEqualToString:version])
	{
		// check if the first use date has been set. if not, set it.
		NSTimeInterval timeInterval = [userDefaults doubleForKey:kGiftKitFirstUseDate];
		if (timeInterval == 0)
		{
			timeInterval = [[NSDate date] timeIntervalSince1970];
			[userDefaults setDouble:timeInterval forKey:kGiftKitFirstUseDate];
		}
		
		// increment the use count
		int useCount = [userDefaults integerForKey:kGiftKitUseCount];
		useCount++;
		[userDefaults setInteger:useCount forKey:kGiftKitUseCount];
		if (GIFTKIT_DEBUG)
			NSLog(@"GIFTKIT Use count: %d", useCount);
	}
	else
	{
		// it's a new version of the app, so restart tracking
		[userDefaults setObject:version forKey:kGiftKitCurrentVersion];
		[userDefaults setDouble:[[NSDate date] timeIntervalSince1970] forKey:kGiftKitFirstUseDate];
		[userDefaults setInteger:1 forKey:kGiftKitUseCount];
		[userDefaults setInteger:0 forKey:kGiftKitSignificantEventCount];
		[userDefaults setBool:NO forKey:kGiftKitGiftedCurrentVersion];
		[userDefaults setBool:NO forKey:kGiftKitDeclinedToGift];
		[userDefaults setDouble:0 forKey:kGiftKitReminderRequestDate];
	}
	
	[userDefaults synchronize];
}

- (void)incrementSignificantEventCount {
	// get the app's version
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
	
	// get the version number that we've been tracking
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *trackingVersion = [userDefaults stringForKey:kGiftKitCurrentVersion];
	if (trackingVersion == nil)
	{
		trackingVersion = version;
		[userDefaults setObject:version forKey:kGiftKitCurrentVersion];
	}
	
	if (GIFTKIT_DEBUG)
		NSLog(@"GIFTKIT Tracking version: %@", trackingVersion);
	
	if ([trackingVersion isEqualToString:version])
	{
		// check if the first use date has been set. if not, set it.
		NSTimeInterval timeInterval = [userDefaults doubleForKey:kGiftKitFirstUseDate];
		if (timeInterval == 0)
		{
			timeInterval = [[NSDate date] timeIntervalSince1970];
			[userDefaults setDouble:timeInterval forKey:kGiftKitFirstUseDate];
		}
		
		// increment the significant event count
		int sigEventCount = [userDefaults integerForKey:kGiftKitSignificantEventCount];
		sigEventCount++;
		[userDefaults setInteger:sigEventCount forKey:kGiftKitSignificantEventCount];
		if (GIFTKIT_DEBUG)
			NSLog(@"GIFTKIT Significant event count: %d", sigEventCount);
	}
	else
	{
		// it's a new version of the app, so restart tracking
		[userDefaults setObject:version forKey:kGiftKitCurrentVersion];
		[userDefaults setDouble:0 forKey:kGiftKitFirstUseDate];
		[userDefaults setInteger:0 forKey:kGiftKitUseCount];
		[userDefaults setInteger:1 forKey:kGiftKitSignificantEventCount];
		[userDefaults setBool:NO forKey:kGiftKitGiftedCurrentVersion];
		[userDefaults setBool:NO forKey:kGiftKitDeclinedToGift];
		[userDefaults setDouble:0 forKey:kGiftKitReminderRequestDate];
	}
	
	[userDefaults synchronize];
}

@end


@interface GiftKit ()
- (void)hideGiftingAlert;
@end

@implementation GiftKit

@synthesize giftingAlert;

- (void)incrementAndGift:(NSNumber*)_canPromptForRating {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self incrementUseCount];
	
	if ([_canPromptForRating boolValue] == YES &&
		[self ratingConditionsHaveBeenMet] &&
		[self connectedToNetwork])
	{
		[self performSelectorOnMainThread:@selector(showGiftingAlert) withObject:nil waitUntilDone:NO];
	}
	
	[pool release];
}

- (void)incrementSignificantEventAndGift:(NSNumber*)_canPromptForRating {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self incrementSignificantEventCount];
	
	if ([_canPromptForRating boolValue] == YES &&
		[self ratingConditionsHaveBeenMet] &&
		[self connectedToNetwork])
	{
		[self performSelectorOnMainThread:@selector(showGiftingAlert) withObject:nil waitUntilDone:NO];
	}
	
	[pool release];
}

+ (void)appLaunched {
	[GiftKit appLaunched:YES];
}

+ (void)appLaunched:(BOOL)canPromptForRating {
	NSNumber *_canPromptForRating = [[NSNumber alloc] initWithBool:canPromptForRating];
	[NSThread detachNewThreadSelector:@selector(incrementAndGift:)
							 toTarget:[GiftKit sharedInstance]
						   withObject:_canPromptForRating];
	[_canPromptForRating release];
}

- (void)hideGiftingAlert {
	if (self.giftingAlert.visible) {
		if (GIFTKIT_DEBUG)
			NSLog(@"GIFTKIT hiding Alert");
		[self.giftingAlert dismissWithClickedButtonIndex:-1 animated:NO];
	}	
}

+ (void)appWillResignActive {
	if (GIFTKIT_DEBUG)
		NSLog(@"GIFTKIT appWillResignActive");
	[[GiftKit sharedInstance] hideGiftingAlert];
}

+ (void)appEnteredForeground:(BOOL)canPromptForRating {
	NSNumber *_canPromptForRating = [[NSNumber alloc] initWithBool:canPromptForRating];
	[NSThread detachNewThreadSelector:@selector(incrementAndGift:)
							 toTarget:[GiftKit sharedInstance]
						   withObject:_canPromptForRating];
	[_canPromptForRating release];
}

+ (void)userDidSignificantEvent:(BOOL)canPromptForRating {
	NSNumber *_canPromptForRating = [[NSNumber alloc] initWithBool:canPromptForRating];
	[NSThread detachNewThreadSelector:@selector(incrementSignificantEventAndGift:)
							 toTarget:[GiftKit sharedInstance]
						   withObject:_canPromptForRating];
	[_canPromptForRating release];
}

+ (void)giftApp {
#if TARGET_IPHONE_SIMULATOR
	NSLog(@"GIFTKIT NOTE: iTunes App Store is not supported on the iOS simulator. Unable to open App Store page.");
#else
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *reviewURL = [templateGiftURL stringByReplacingOccurrencesOfString:@"APP_ID" withString:[NSString stringWithFormat:@"%d", GIFTKIT_APP_ID]];
	[userDefaults setBool:YES forKey:kGiftKitGiftedCurrentVersion];
	[userDefaults synchronize];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
#endif
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	switch (buttonIndex) {
		case 0:
		{
			// they don't want to gift it
			[userDefaults setBool:YES forKey:kGiftKitDeclinedToGift];
			[userDefaults synchronize];
			break;
		}
		case 1:
		{
			// they want to gift it
			[GiftKit giftApp];
			break;
		}
		case 2:
			// remind them later
			[userDefaults setDouble:[[NSDate date] timeIntervalSince1970] forKey:kGiftKitReminderRequestDate];
			[userDefaults synchronize];
			break;
		default:
			break;
	}
}

@end