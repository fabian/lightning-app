//
//  LightningAppDelegate.h
//  Lightning
//
//  Created by Cyril Gabathuler on 15.02.10.
//  Copyright Bahnhofstrasse 24, 5400 Baden 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h> 
#import <CoreData/CoreData.h>

@interface LightningAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	UINavigationController *navigationController;
	
	NSManagedObjectContext *context;
	NSManagedObjectModel *model;
	NSPersistentStoreCoordinator *psc;
	
	NSURL *apiUrl;
	NSString *deviceToken;
	
}

- (void)setupPersistentStore;
- (void)setupLightning;
- (NSString *)applicationDocumentsDirectory;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;

@property (retain, nonatomic) NSManagedObjectContext *context;
@property (retain, nonatomic) NSManagedObjectModel *model;
@property (retain, nonatomic) NSPersistentStoreCoordinator *psc;

@property (retain, nonatomic) NSURL *apiUrl;
@property (retain, nonatomic) NSString *deviceToken;

@end

