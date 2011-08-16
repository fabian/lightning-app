//
//  ListsViewController.h
//  Lightning
//
//  Created by Cyril Gabathuler on 15.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Lists.h"
#import "AddListViewController.h"
#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>
#import "Lightning.h"
#import "LightningAPI.h"

@interface ListsViewController : UITableViewController <AddListViewControllerDelegate, LightningDelegate, LightningAPIListsDelegate, LightningAPIAddListDelegate>{
	Lists *lists;
	NSManagedObjectContext *context;
	NSMutableArray *listNames;
}

-(id)initWithStyle:(UITableViewStyle)style andContext:(NSManagedObjectContext*)initContext;
-(void) addList;
-(void) setupModel;

@property (nonatomic, retain) Lists *lists;
@property (retain, nonatomic) NSManagedObjectContext *context;
@property (retain, nonatomic) NSMutableArray *listNames;
@property (retain, nonatomic) LightningAPI *lightningAPI;

@end
