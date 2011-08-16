//
//  ListViewController.h
//  Lightning
//
//  Created by Cyril Gabathuler on 15.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ListEntries.h"
#import	"ListName.h"
#import <CoreData/CoreData.h>
#import "Lightning.h"
#import "ItemTableViewCell.h"
#import "LightningAPI.h"

@interface ListViewController : UITableViewController <UITextFieldDelegate, UITextInputTraits, LightningDelegate> {
	ListEntries *listEntries;
	Boolean keyboardShown;
	ItemTableViewCell *activeCell;
	NSArray *listItems;
	ListName *listName;
	NSManagedObjectContext *context;
	UITextField *doneTextField;
	NSString *addListName;
	NSTimer *timer;
	
}

- (void)registerForKeyboardNotifications;
- (void)doneAdding;

@property (nonatomic, retain) ListEntries *listEntries;
@property (nonatomic, retain) NSArray *listItems;
@property (nonatomic, retain) ListName *listName;
@property (nonatomic, retain) UITextField *doneTextField;
@property (nonatomic, retain) NSString *addListName;
@property (retain, nonatomic) NSManagedObjectContext *context;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) LightningAPI *lightningAPI;

@end
