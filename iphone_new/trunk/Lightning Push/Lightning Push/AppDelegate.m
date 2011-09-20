//
//  AppDelegate.m
//  Lightning Push
//
//  Created by Cyril Gabathuler on 06.09.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

#import "ListsViewController.h"
#import "LightningUtil.h"
#import "MTStatusBarOverlay.h"

@interface UINavigationBar (MyCustomNavBar)
@end
@implementation UINavigationBar (MyCustomNavBar)
- (void) drawRect:(CGRect)rect {
    UIImage *barImage = [UIImage imageNamed:@"tabbar.png"];
    [barImage drawInRect:rect];
}
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize navigationController = _navigationController;
@synthesize lightningAPI = _lightningAPI;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"tabbar"] forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTintColor: [[UIColor alloc ]initWithRed:0 green:0 blue:0 alpha:0.1]];
    
    //push notification
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    
    //init LightningAPI
    self.lightningAPI = [LightningAPI sharedManager];
    [self.lightningAPI initLightningWithContext:self.managedObjectContext];

    ListsViewController *masterViewController = [[ListsViewController alloc] initWithStyle:UITableViewStylePlain];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];

    //[self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    
    masterViewController.managedObjectContext = self.managedObjectContext;
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSLog(@"handelopenurl");
    
	if (![[url scheme] isEqualToString:@"lightning"] && ![[url host] isEqualToString:@"list"]) {
		return FALSE;
	}
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	for (NSString* param in [[url query] componentsSeparatedByString:@"&"]) {
		NSArray* elts = [param componentsSeparatedByString:@"="];
		[params setObject:[elts objectAtIndex:1] forKey:[elts objectAtIndex:0]];
	}
	
	NSString *listId = [[[url path] pathComponents]	objectAtIndex:1];
    NSString *token = [params objectForKey:@"token"];
    
	NSLog(@"token %@", [params objectForKey:@"token"]);
	NSLog(@"listId %@", [[[url path] pathComponents] objectAtIndex:1]);
	
	[self.lightningAPI shareList:listId token:token];
	
	return TRUE;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    NSEntityDescription * entity   = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.managedObjectContext];
    
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"hasUnread == 1"];
    
    NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
    [fetch setEntity: entity];
    [fetch setPredicate:predicate];
    
    NSArray * results = [self.managedObjectContext executeFetchRequest:fetch error:nil];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[results count]];   
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    //refresh CoreData
    [LightningUtil updateData:self.managedObjectContext];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Lightning_Push" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Lightning_Push2.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Push Notification

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    NSLog(@"Registered for push with token %@", [devToken description]);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setObject:[devToken description] forKey:@"deviceToken"];
       
#warning new method for username
    [self.lightningAPI updateDevice:[devToken description] Name:@"test"];
    
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    NSLog(@"Fail to register for push");
    
    MTStatusBarOverlay *overlay = [MTStatusBarOverlay sharedInstance];
    overlay.animation = MTStatusBarOverlayAnimationNone;  // MTStatusBarOverlayAnimationShrink
    overlay.detailViewMode = MTDetailViewModeDetailText;         // enable automatic history-tracking and show in detail-view
    [overlay postImmediateFinishMessage:@"Following was a good idea!" duration:2.0 animated:YES];
    overlay.progress = 1.0;

}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	NSLog(@"remotenotification was send %@", [[userInfo objectForKey:@"aps"] objectForKey:@"lightning_list"]);
    NSLog(@"remotenotification was send %@", [userInfo description]);
    
    MTStatusBarOverlay *overlay = [MTStatusBarOverlay sharedInstance];
    overlay.animation = MTStatusBarOverlayAnimationNone;  // MTStatusBarOverlayAnimationShrink
    overlay.detailViewMode = MTDetailViewModeDetailText;         // enable automatic history-tracking and show in detail-view
    [overlay postImmediateFinishMessage:[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] duration:2.0 animated:YES];
    overlay.progress = 1.0;

	
	NSString *listId = [[userInfo objectForKey:@"aps"] objectForKey:@"lightning_list"];
    
    [LightningUtil updateData:self.managedObjectContext];
	
	if ([application applicationState] == UIApplicationStateInactive) {
		NSLog(@"came from background");
		
	} else if ([application applicationState] == UIApplicationStateActive) {
		//no button
		NSLog(@"front");
        
        		
		//[LightningUtil updateData:managedObjectContext navigationController:self.navigationController];
	}
}

@end
