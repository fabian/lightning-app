//
//  ShareListViewController.h
//  Lightning
//
//  Created by Cyril Gabathuler on 24.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddNewGroup.h";
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "Lightning.h";
#import <CoreData/CoreData.h>
#import "ListName.h"

@protocol AddListViewControllerDelegate;

@interface AddListViewController : UITableViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, AddNewGroupDelegate, MFMailComposeViewControllerDelegate, LightningDelegate>{
	id <AddListViewControllerDelegate> delegate;
	NSIndexPath *indexPathCell1;
	NSIndexPath *indexPathCell2;
	UITextField *listNameTextField;
	int checkmark;
	NSManagedObjectContext *context;
	ListName *sharedList;
}

@property (nonatomic, retain) NSIndexPath *indexPathCell1;
@property (nonatomic, retain) NSIndexPath *indexPathCell2;
@property (nonatomic) int checkmark;
@property (nonatomic, retain) UITextField *listNameTextField;
@property (nonatomic, retain) NSManagedObjectContext *context;
@property (nonatomic, retain) ListName *sharedList;

@property (assign) id <AddListViewControllerDelegate> delegate;

- (void)doneAddList;
- (void)showLoadingView;

@end

@protocol AddListViewControllerDelegate <NSObject>

- (void)finishAddList:(NSString *)listName;
- (void)finishAddSharedList:(NSManagedObjectID *)objectID;

@end
