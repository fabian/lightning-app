//
//  ListsViewController.h
//  Lightning
//
//  Created by Cyril Gabathuler on 15.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Lists.h";
#import "AddListViewController.h";
#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>

@interface ListsViewController : UITableViewController <AddListViewControllerDelegate>{
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

@end
