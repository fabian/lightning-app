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


@interface ListViewController : UITableViewController <UITextFieldDelegate, UITextInputTraits> {
	ListEntries *listEntries;
	Boolean keyboardShown;
	UITableViewCell *activeCell;
	NSArray *listItems;
	ListName *listName;
	NSManagedObjectContext *context;
	UITextField *doneTextField;
	
}

- (void)registerForKeyboardNotifications;
- (void)doneAdding;

@property (nonatomic, retain) ListEntries *listEntries;
@property (nonatomic, retain) NSArray *listItems;
@property (nonatomic, retain) ListName *listName;
@property (nonatomic, retain) UITextField *doneTextField;
@property (retain, nonatomic) NSManagedObjectContext *context;

@end
