//
//  LightningAppDelegate.m
//  Lightning
//
//  Created by Cyril Gabathuler on 15.02.10.
//  Copyright Bahnhofstrasse 24, 5400 Baden 2010. All rights reserved.
//

#import "LightningAppDelegate.h"
#import "ListsViewController.h";
#import "Lightning.h";

@implementation LightningAppDelegate

@synthesize window;
@synthesize navigationController, model, context, psc, apiUrl, deviceToken;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	NSLog(@"launch options %@", [launchOptions description]);
	[self setupUsername];
	self.apiUrl = [NSURL URLWithString:@"https://lightning-app.appspot.com/api/"];
	
	//Setup Core Data
	self.model = [NSManagedObjectModel mergedModelFromBundles:nil];
	[self setupPersistentStore];
	context = [NSManagedObjectContext new];
	[context setPersistentStoreCoordinator:psc];
	
	if(context == nil)
		NSLog(@"appdelegate context is nil");
	
	//override init method to use context
	ListsViewController *listsViewController = [[ListsViewController alloc] initWithStyle:UITableViewStylePlain andContext:context];
	
	UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:listsViewController];
	aNavigationController.navigationBar.barStyle = UIBarStyleBlack;
	aNavigationController.navigationBar.translucent = YES;
	
	self.navigationController = aNavigationController;
	
	[listsViewController release];
	[aNavigationController release];
	
	[window addSubview:[navigationController view]];
	
    // Override point for customization after application launch
    [window makeKeyAndVisible];
	
	//push notification
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
	
	return TRUE;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	if (![[url scheme] isEqualToString:@"lightning"] && ![[url host] isEqualToString:@"list"]) {
		return FALSE;
	}
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	for (NSString* param in [[url query] componentsSeparatedByString:@"&"]) {
		NSArray* elts = [param componentsSeparatedByString:@"="];
		[params setObject:[elts objectAtIndex:1] forKey:[elts objectAtIndex:0]];
	}
	
	NSString *listId = [[[url path] pathComponents]	objectAtIndex:1];

	NSLog(@"token %@", [params objectForKey:@"token"]);
	NSLog(@"listId %@", [[[url path] pathComponents] objectAtIndex:1]);
	
	//getlistsview delegate?
	Lightning *lightning = [[Lightning alloc]init];
	lightning.delegate = self;
	lightning.url = [NSURL URLWithString:@"https://lightning-app.appspot.com/api/"];
	[lightning shareList:listId token:[params objectForKey:@"token"]];
	
	return TRUE;
}

- (void)setupUsername {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if ([userDefaults objectForKey:@"username"] != nil) {
		return;
	}
	
	NSString *username = [[UIDevice currentDevice] name];
	
	[userDefaults setValue:username forKey:@"username"];
	
	[username release];
}

- (void)setupLightning {
	Lightning *lighting = [[Lightning alloc] initWithURL:self.apiUrl andDeviceToken:self.deviceToken username:[self getUsername]];
}

- (NSString *)getUsername {
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	return [userDefaults objectForKey:@"username"];
}

- (void)setupPersistentStore
{
	NSString *docDir = [self applicationDocumentsDirectory];
	NSString *pathToDb = [docDir stringByAppendingPathComponent:@"Lightning8.sqlite"];
	
	NSURL *urlForPath = [NSURL fileURLWithPath:pathToDb];
	NSError *error;
	
	psc = [[NSPersistentStoreCoordinator alloc]initWithManagedObjectModel:self.model];
	
	if(![psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:urlForPath options:nil error:&error])
	{
		// error handling
		NSLog(@"Problem with setupPersistenStore");
	}
}

- (NSString *)applicationDocumentsDirectory
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	
	return basePath;
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    const void *devTokenBytes = [devToken bytes];
	
	self.deviceToken = [devToken description];
	
	self.setupLightning;	
	
	NSLog(@"bytes in hex: %@", [devToken description]);
	//self.registered = YES;
    //[self sendProviderDeviceToken:devTokenBytes]; // custom method
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
	//simulator testing
	self.deviceToken = @"56388792DCFAA3C4A08CDBAFEE90467607C44C8196A021BEEBC5AE7988164EAA";
	self.setupLightning;
	
    NSLog(@"Error in registration. Error: %@", err);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	NSLog(@"remotenotification was send %@", [[userInfo objectForKey:@"lightning"] description]);
	
	if ([application applicationState] == UIApplicationStateInactive) {
		//tapped button
		NSLog(@"came from background");
	} else if ([application applicationState] == UIApplicationStateActive) {
		//no button
		NSLog(@"front");
	}
}

- (void)applicationWillResignActive:(UIApplication *)application {
	NSLog(@"nownow??");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	NSError *error;
	
	if(context != nil)
	{
		if([context hasChanges] && ! [context save:&error])
		{
			//error handling
		}
	}
}

- (void)dealloc {
    [window release];
    [super dealloc];
}


@end
