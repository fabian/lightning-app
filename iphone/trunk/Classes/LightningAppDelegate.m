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
@synthesize navigationController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {   
	
	NSString *device = @"http://localhost:8080/api/devices/1?secret=7e01caa1a4f161323c70b140cbe367f067057d3186918e0f8fe88b5447e5c0c020fc623371785ac4ee8d99d85b066bbd1df45777dc805c8e2307b1ee6e36c808";
	NSURL *url = [NSURL URLWithString:@"http://localhost:8080/api/"];
	Lightning *api = [[Lightning alloc] initWithURL:url andDevice:device];
	//Lightning *api = [[Lightning alloc] initWithURL:url];
	//[api addListWithTitle:@"Foobar"];
	[api getLists];
	
	ListsViewController *listsViewController = [[ListsViewController alloc] initWithStyle:UITableViewStylePlain];
	UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:listsViewController];
	aNavigationController.navigationBar.barStyle = UIBarStyleBlack;
	aNavigationController.navigationBar.translucent = YES;
	
	[aNavigationController setToolbarHidden:NO animated:YES];
	aNavigationController.toolbar.barStyle = UIBarStyleBlackOpaque;
	aNavigationController.toolbar.translucent = YES;
	
	self.navigationController = aNavigationController;
	
	[listsViewController release];
	[aNavigationController release];
	
	[window addSubview:[navigationController view]];

    // Override point for customization after application launch
    [window makeKeyAndVisible];
}


- (void)dealloc {
    [window release];
    [super dealloc];
}


@end
