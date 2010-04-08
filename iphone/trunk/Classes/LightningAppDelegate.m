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
@synthesize navigationController, model, context, psc;


- (void)applicationDidFinishLaunching:(UIApplication *)application {   
	
	self.setupLightning;
	
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
}

- (void)setupLightning {
	NSString *device = @"http://localhost:8080/api/devices/52?secret=441b230ee803430aa7c22a508551bc4f80d546648982287d8cb9b687f0334011b39a9388833512ef316e49f5e430a84ac0063f0df452f3224904d1600ffc0509";
	NSURL *url = [NSURL URLWithString:@"http://localhost:8080/api/"];
	Lightning *api = [[Lightning alloc] initWithURL:url andDevice:device];
	//Lightning *api = [[Lightning alloc] initWithURL:url];
	[api addListWithTitle:@"Foobar"];
	[api getLists];
}

- (void)setupPersistentStore
{
	NSString *docDir = [self applicationDocumentsDirectory];
	NSString *pathToDb = [docDir stringByAppendingPathComponent:@"Lightning.sqlite"];
	
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
