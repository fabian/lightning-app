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
#import "ListViewController.h";
#import "LightningUtil.h";
#import "Device.h";

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
	lightning.delegate = [self.navigationController topViewController];
	lightning.context = self.context;
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
	Lightning *lighting = [[Lightning alloc] initWithURL:self.apiUrl andDeviceToken:self.deviceToken username:[self getUsername] context:self.context];
}

- (NSString *)getUsername {
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	return [userDefaults objectForKey:@"username"];
}

- (void)setupPersistentStore
{
	NSString *docDir = [self applicationDocumentsDirectory];
	NSString *pathToDb = [docDir stringByAppendingPathComponent:@"Lightning17.sqlite"];
	
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
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSError *error;
	NSFetchRequest *req = [NSFetchRequest new];
	if(self.context == nil)
		NSLog(@"context is nil");
	NSEntityDescription *descr = [NSEntityDescription entityForName:@"Device" inManagedObjectContext:self.context];
	[req setEntity:descr];
	
	NSArray * results = [context executeFetchRequest:req error:nil];
	[req release];
	
	
	if ([userDefaults valueForKey:@"lightningId"] != nil && [userDefaults valueForKey:@"lightningSecret"] != nil) {
		Lightning *updateLightning = [[[Lightning alloc]init] autorelease];
		updateLightning.url = [NSURL URLWithString:@"https://lightning-app.appspot.com/api/"];
		[updateLightning updateDevice:self.deviceToken andName:[self getUsername] context:self.context];
	} else if ([results count] > 0) {
		Device *device = [results objectAtIndex:0];
		
		[userDefaults setValue:device.lightningId forKey:@"lightningId"];
		[userDefaults setValue:device.lightningId forKey:@"lightningSecret"];
		
		device.deviceName = [self getUsername];
		device.deviceIdentifier = [UIDevice currentDevice].uniqueIdentifier;
		
		[context save:&error];
		
		Lightning *updateLightning = [[[Lightning alloc]init] autorelease];
		updateLightning.url = [NSURL URLWithString:@"https://lightning-app.appspot.com/api/"];
		[updateLightning updateDevice:self.deviceToken andName:[self getUsername] context:self.context];
	} else {
		self.setupLightning;
	}

	NSLog(@"bytes in hex: %@", [devToken description]);
	//self.registered = YES;
    //[self sendProviderDeviceToken:devTokenBytes]; // custom method
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
	//simulator testing
	self.deviceToken = @"56388792DCFAA3C4A08CDBAFEE90467607C44C8196A021BEEBC5AE7988164EAA";
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSError *error;
	NSFetchRequest *req = [NSFetchRequest new];
	if(self.context == nil)
		NSLog(@"context is nil");
	NSEntityDescription *descr = [NSEntityDescription entityForName:@"Device" inManagedObjectContext:self.context];
	[req setEntity:descr];
	
	NSArray * results = [context executeFetchRequest:req error:nil];
	[req release];
	
	
	if ([userDefaults valueForKey:@"lightningId"] != nil && [userDefaults valueForKey:@"lightningSecret"] != nil) {
		Lightning *updateLightning = [[[Lightning alloc]init] autorelease];
		updateLightning.url = [NSURL URLWithString:@"https://lightning-app.appspot.com/api/"];
		[updateLightning updateDevice:self.deviceToken andName:[self getUsername] context:self.context];
	} else if ([results count] > 0) {
		Device *device = [results objectAtIndex:0];
		
		[userDefaults setValue:device.lightningId forKey:@"lightningId"];
		[userDefaults setValue:device.lightningId forKey:@"lightningSecret"];
		
		device.deviceName = [self getUsername];
		device.deviceIdentifier = [UIDevice currentDevice].uniqueIdentifier;
		
		[context save:&error];
		
		Lightning *updateLightning = [[[Lightning alloc]init] autorelease];
		updateLightning.url = [NSURL URLWithString:@"https://lightning-app.appspot.com/api/"];
		[updateLightning updateDevice:self.deviceToken andName:[self getUsername] context:self.context];
	} else {
		self.setupLightning;
	}
	
    NSLog(@"Error in registration. Error: %@", err);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	NSLog(@"remotenotification was send %@", [[userInfo objectForKey:@"aps"] objectForKey:@"lightning_list"]);
	
	NSString *listId = [[userInfo objectForKey:@"aps"] objectForKey:@"lightning_list"];
	
	if ([application applicationState] == UIApplicationStateInactive) {
		//tapped button
		NSLog(@"came from background");
		
		[LightningUtil updateData:self.context navigationController:self.navigationController];
		
		NSEntityDescription *entity   = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.context];
		NSPredicate * predicate;
		predicate = [NSPredicate predicateWithFormat:@"listId == %@", listId];
		
		NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
		[fetch setEntity: entity];
		[fetch setPredicate: predicate];
		
		NSArray * results = [context executeFetchRequest:fetch error:nil];
		[fetch release];
		
		if ([results count] == 1) {
			ListName *listName = [results objectAtIndex:0];
			
			ListViewController *listViewController = [[ListViewController alloc] initWithStyle:UITableViewStylePlain listName:listName];
			listViewController.listName = listName;
			listViewController.context = context;
			
			NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"creation" ascending:YES];
			NSMutableArray *sorted = [[NSMutableArray alloc] initWithArray:[listName.listItems allObjects]];
			[sorted sortUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
			listViewController.listItems = sorted;
			
			[sorted release];
			
			[listViewController registerForKeyboardNotifications];
			
			[self.navigationController popToRootViewControllerAnimated:NO];
			
			[self.navigationController pushViewController:listViewController animated:YES];
			[listViewController release];
		}
		
	} else if ([application applicationState] == UIApplicationStateActive) {
		//no button
		NSLog(@"front");
		
		[LightningUtil updateData:self.context navigationController:self.navigationController];
	}
}

- (void)applicationWillResignActive:(UIApplication *)application {
	NSLog(@"nownow??");
	
	//recount badge number
	NSEntityDescription *entity   = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.context];
	
	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
	[fetch setEntity: entity];
	
	NSArray * results = [context executeFetchRequest:fetch error:nil];
	[fetch release];
	
	int badgeNumber = 0;
	
	for (ListName *listName in results) {
		badgeNumber += [listName.unreadCount intValue];
	}
	
	[UIApplication sharedApplication].applicationIconBadgeNumber = badgeNumber;
	
}

-(void)applicationDidBecomeActive:(UIApplication *)application {
	NSLog(@"didbecomeactive");
	
	[LightningUtil updateData:self.context navigationController:self.navigationController];

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
