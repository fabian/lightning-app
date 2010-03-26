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
	
	NSString *device = @"http://localhost:8080/api/devices/4?secret=3af5e21c38d25eaaa4f186a14ca13f046c004e83736e39c8927cb72962d94f94baa3124a7eca1f0e3fbb1f9f679d9baf63e183c1a57c59c19537e450f36016b9";
	NSURL *url = [NSURL URLWithString:@"http://localhost:8080/api/"];
	Lightning *api = [[Lightning alloc] initWithURL:url andDevice:device];
	//Lightning *api = [[Lightning alloc] initWithURL:url];
	[api addListWithTitle:@"Foobar"];
	[api getLists];
	
	ListsViewController *listsViewController = [[ListsViewController alloc] initWithStyle:UITableViewStylePlain];
	
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


- (void)dealloc {
    [window release];
    [super dealloc];
}


@end
