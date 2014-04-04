//
//  LSApplication.m
//  LostSeries
//
//  Created by Grigory Zubankov on 10/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// UI
#import <UIComponents/UIStatusBarView.h>
// Logic
#import "LSApplication.h"
#import "LSCDID.h"



@interface LSMessageMBH ()

@property BOOL closed;
@property (readonly) NSString* text;
@property (readonly) double delay;

@end

@implementation LSMessageMBH
{
  NSString* theMessage;
  double theDelay;
  BOOL theFlagClosed;
}

@synthesize closed = theFlagClosed;
@synthesize text = theMessage;
@synthesize delay = theDelay;

- (id) initWithMessage:(NSString*) message delay:(double)delay
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  theMessage = message;
  theDelay = delay;
  //
  return self;
}

@end


typedef enum
{
  LSMessageBlackHoleStatePreIntro,
  LSMessageBlackHoleStatePreMessage,
  LSMessageBlackHoleStateMessage,
  LSMessageBlackHoleStatePostMessage,
  LSMessageBlackHoleStatePostIntro,
} LSMessageBlackHoleState;


//
// LSMessageBlackHole
//

@implementation LSMessageBlackHole
{
  NSMutableArray* theQueueMessage;
  UIWindow* theWindowMessage;
  UIStatusBarView* theViewMessage;
  UIWindow* theStatusBarWindow;
  UIView* theViewStatusBarSnapshot;
  //
  LSMessageBlackHoleState theState;
}

- (id) init
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  theQueueMessage = [NSMutableArray array];
  theState = LSMessageBlackHoleStatePreIntro;
  //
  theStatusBarWindow = [[UIWindow alloc] initWithFrame:[self rectStatusBar]];
  [theStatusBarWindow setWindowLevel:UIWindowLevelStatusBar+1];
  [theStatusBarWindow makeKeyAndVisible];
  [theStatusBarWindow setHidden:YES];
  //
  theWindowMessage = [[UIWindow alloc] initWithFrame:[self rectAboveStatusBar]];
  [theWindowMessage setWindowLevel:UIWindowLevelStatusBar+1];
  [theWindowMessage makeKeyAndVisible];
  [theWindowMessage setHidden:NO];
  //
  theViewMessage = [[UIStatusBarView alloc] initWithFrame:[self rectStatusBar]];
  [theWindowMessage.viewForBaselineLayout addSubview:theViewMessage];
  //
  return self;
}

- (UIView*) viewStatusBar
{
  // obfuscated status bar name
  NSData* data = [NSData dataWithBytes:(unsigned char[]){0x73, 0x74, 0x61, 0x74, 0x75, 0x73, 0x42, 0x61, 0x72} length:9];
  NSString* key = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
  id object = [UIApplication sharedApplication];
  UIView* statusBar = nil;
  if([object respondsToSelector:NSSelectorFromString(key)])
  {
    statusBar = [object valueForKey:key];
  }
  return statusBar;
}

- (UIImageView*) createImageViewWithStatusBarSnapshot
{
  UIView* statusBarView = [self viewStatusBar];
  //
  CGRect rect = [statusBarView bounds];
  UIGraphicsBeginImageContextWithOptions(rect.size, NO, .0);
  [statusBarView.layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage* capturedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  //
  return [[UIImageView alloc] initWithImage:capturedImage];
}

- (void) updateStatusBarSnapshot
{
  [theViewStatusBarSnapshot removeFromSuperview];
  theViewStatusBarSnapshot = [self createImageViewWithStatusBarSnapshot];
  [theStatusBarWindow.viewForBaselineLayout addSubview:theViewStatusBarSnapshot];
}

- (void) queueNotification:(NSString*)text delay:(double)delay
{
  LSMessageMBH* message = [self queueManagedNotification:text delay:delay];
  [self closeMessage:message];
}

- (LSMessageMBH*) queueManagedNotification:(NSString*)text delay:(double)delay
{
  LSMessageMBH* message = [[LSMessageMBH alloc] initWithMessage:text delay:delay];
  [theQueueMessage addObject:message];
  //
  if (theState == LSMessageBlackHoleStatePreIntro)
  {
    [self handleNext];
  }
  //
  return message;
}

- (void) closeMessage:(LSMessageMBH*)message
{
  BOOL wasClosed = message.closed;
  message.closed = YES;
  //
  if (theState == LSMessageBlackHoleStatePostMessage && [theQueueMessage firstObject] == message && !wasClosed)
  {
    [self handleNext];
  }
}

- (void) handleNext
{
  if (theState == LSMessageBlackHoleStatePreIntro)
  {
    theState  = LSMessageBlackHoleStatePreMessage;
    
    [self updateStatusBarSnapshot];
    theStatusBarWindow.frame = [self rectStatusBar];
    [theStatusBarWindow setHidden:NO];
    [self viewStatusBar].hidden = YES;
    
    [UIView animateWithDuration:.3 delay:.0 options:0 animations:^
    {
      theStatusBarWindow.frame = [self rectAboveStatusBar];
    }
    completion:^(BOOL finished)
    {
      [self handleNext];
    }];
    
  }
  else if (theState == LSMessageBlackHoleStatePreMessage)
  {
    if (theQueueMessage.count)
    {
      theState = LSMessageBlackHoleStateMessage;
      
      __block LSMessageMBH* message = [theQueueMessage firstObject];
      [theViewMessage setText:message.text];
      
      [UIView animateWithDuration:.3 delay:.0 options:0 animations:^
      {
        theWindowMessage.frame = [self rectStatusBar];
      }
      completion:^(BOOL finished)
      {
       [NSTimer scheduledTimerWithTimeInterval:message.delay target:self selector:@selector(onTimer:) userInfo:message repeats:NO];
      }];

    }
    else
    {
      theState = LSMessageBlackHoleStatePostIntro;
    }
  }
  else if (theState == LSMessageBlackHoleStateMessage)
  {
    theState = LSMessageBlackHoleStatePostMessage;
    [self handleNext];
  }
  else if (theState == LSMessageBlackHoleStatePostMessage)
  {
    LSMessageMBH* message = [theQueueMessage firstObject];
    if (!message.closed)
    {
      return;
    }

    theState = theQueueMessage.count > 1
      ? LSMessageBlackHoleStatePreMessage
      : LSMessageBlackHoleStatePostIntro;
   
    [UIView animateWithDuration:.3 delay:.0 options:0 animations:^
    {
      theWindowMessage.frame = [self rectAboveStatusBar];
    }
    completion:^(BOOL finished)
    {
      [theQueueMessage removeObjectAtIndex:0];
      [self handleNext];
    }];
  }
  else if (theState == LSMessageBlackHoleStatePostIntro)
  {
    theState = LSMessageBlackHoleStatePreIntro;
    
    [UIView animateWithDuration:.3 delay:.0 options:0 animations:^
    {
      theStatusBarWindow.frame = [self rectStatusBar];
    }
    completion:^(BOOL finished)
    {
      [self viewStatusBar].hidden = NO;
      [theStatusBarWindow setHidden:YES];
    }];
  }
}

- (void) onTimer:(NSTimer*)timer
{
  [self handleNext];
}

- (CGRect) rectStatusBar
{
  return [[UIApplication sharedApplication] statusBarFrame];
}

- (CGRect) rectAboveStatusBar
{
  CGRect rect = [self rectStatusBar];
  rect.origin.y -= rect.size.height;
  return rect;
}

@end


//
// LSApplication
//

@interface LSApplication ()
{
  LSModelBase* theModelBase;
  LSServiceArtworkGetter* theServiceArtworkGetter;
  LSMessageBlackHole* theMBH;
  LSRegistryControllers* theRegistryControllers;
  NSString* theDeviceToken;
  LSCDID* theCDID;
}
@end

@implementation LSApplication

+ (LSApplication*) singleInstance
{
  static __weak LSApplication* weakSingleInstance = nil;
  if (weakSingleInstance == nil)
  {
    LSApplication* singleInstance = [[LSApplication alloc] init];
    weakSingleInstance = singleInstance;
    return singleInstance;
  }
  return weakSingleInstance;
}

- (id) init
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  return self;

}

- (NSString*) deviceToken
{
  return theDeviceToken;
}

- (void) setDeviceToken:(NSString *)deviceToken
{
  theDeviceToken = deviceToken;
  [[NSNotificationCenter defaultCenter] postNotificationName:LSApplicationDeviceTokenDidRecieveNotification object:self];
}

- (LSModelBase*) modelBase
{
  return theModelBase;
}

- (LSServiceArtworkGetter*) serviceArtworkGetter
{
  if (!theServiceArtworkGetter)
  {
    theServiceArtworkGetter = [[LSServiceArtworkGetter alloc] initWithData:theModelBase];
  }
  return theServiceArtworkGetter;
}

- (LSMessageBlackHole*) messageBlackHole
{
  if (!theMBH)
  {
    theMBH = [[LSMessageBlackHole alloc] init];
  }
  return theMBH;
}

- (LSRegistryControllers*) registryControllers
{
  if (!theRegistryControllers)
  {
    theRegistryControllers = [[LSRegistryControllers alloc] init];
  }
  return theRegistryControllers;
}

- (void) ubiquitousKeyValueStoreDidChangeExternallyWithReason:(NSInteger)reason changedKeys:(NSArray*)keysChanged
{
  if (reason == NSUbiquitousKeyValueStoreServerChange || reason == NSUbiquitousKeyValueStoreInitialSyncChange)
  {
    for (NSString* key in keysChanged)
    {
      // CDID
      if ([key isEqualToString:@"CDID"])
      {
        theCDID = [self getUpdatedCDID];
      }
    }
  }
}

- (LSCDID*) getUpdatedCDID
{
  LSCDID* cdidThisDevice = [[LSCDID alloc] initWithString:[[UIDevice currentDevice] identifierForVendor].UUIDString];
  LSCDID* cdid = [[LSCDID alloc] initWithAnother:theCDID
    ? theCDID
    : cdidThisDevice];
  //
  NSArray* arrayWithCDID = [[NSUbiquitousKeyValueStore defaultStore] arrayForKey:@"CDID"];
  if (arrayWithCDID)
  {
    LSCDID* cdidCommon = [[LSCDID alloc] initWithRaw:arrayWithCDID];
    [cdid merge:cdidCommon];
  }
  [[NSUbiquitousKeyValueStore defaultStore] setArray:cdid.raw forKey:@"CDID"];
  return cdid;
}

- (void) registerForRemoteNotifications
{
  [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
    UIRemoteNotificationTypeBadge |
    UIRemoteNotificationTypeSound |
    UIRemoteNotificationTypeAlert];
}

- (void) registerForUbiquitousKeyValueStoreNotifications
{
  [[NSNotificationCenter defaultCenter]
    addObserverForName: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
    object: [NSUbiquitousKeyValueStore defaultStore]
    queue: nil
    usingBlock:^(NSNotification *notification)
    {
      NSNumber* reasonForChange = [[notification userInfo] objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey];
      NSArray* keysChanged = [[notification userInfo] objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
      if (reasonForChange)
      {
        [self ubiquitousKeyValueStoreDidChangeExternallyWithReason:reasonForChange.integerValue changedKeys:keysChanged];
      }
    }
  ];
  [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

#pragma mark - UIApplicationDelegate implementation

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	theCDID = [self getUpdatedCDID];
  [theCDID toString];
  theModelBase = [[LSModelBase alloc] init];
  //
  [self registerForRemoteNotifications];
  [self registerForUbiquitousKeyValueStoreNotifications];
  //
  return YES;
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
  NSString* strDeviceToken = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
  strDeviceToken = [strDeviceToken stringByReplacingOccurrencesOfString:@" " withString:@""];
  //
  self.deviceToken = strDeviceToken;
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
  // "remote notifications are not supported in the simulator"
  if (error.code == 3010)
  {
    self.deviceToken = @"99c2a09abce108cdea3a09c309323926a24b68dfbc78b790b28c520e93ff61fd";
  }
}

@end


NSString* LSApplicationDeviceTokenDidRecieveNotification = @"LSApplicationDeviceTokenDidRecieveNotification";
