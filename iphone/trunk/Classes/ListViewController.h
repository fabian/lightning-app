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
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface ListViewController : UITableViewController <UITextFieldDelegate, UITextInputTraits, LightningDelegate, MFMailComposeViewControllerDelegate> {
	ListEntries *listEntries;
	Boolean keyboardShown;
	UITableViewCell *activeCell;
	NSArray *listItems;
	ListName *listName;
	NSManagedObjectContext *context;
	UITextField *doneTextField;
	BOOL showMail;
	NSString *addListName;
	
}

- (void)registerForKeyboardNotifications;
- (void)doneAdding;

@property (nonatomic, retain) ListEntries *listEntries;
@property (nonatomic, retain) NSArray *listItems;
@property (nonatomic, retain) ListName *listName;
@property (nonatomic, retain) UITextField *doneTextField;
@property (nonatomic, retain) NSString *addListName;
@property (retain, nonatomic) NSManagedObjectContext *context;
@property BOOL showMail;

@end
