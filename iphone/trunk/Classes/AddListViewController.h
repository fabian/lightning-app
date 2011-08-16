//
//  ShareListViewController.h
//  Lightning
//
//  Created by Cyril Gabathuler on 24.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "Lightning.h"
#import <CoreData/CoreData.h>
#import "ListName.h"
#import "LightningAppDelegate.h"
#import "LightningAPI.h"

@protocol AddListViewControllerDelegate;

@interface AddListViewController : UITableViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate, LightningAPIAddListDelegate>{
	NSObject <AddListViewControllerDelegate> *delegate;
	UITextField *listNameTextField;
	int checkmark;
	NSManagedObjectContext *context;
	ListName *sharedList;
}

@property (nonatomic) int checkmark;
@property (nonatomic, retain) UITextField *listNameTextField;
@property (nonatomic, retain) NSManagedObjectContext *context;
@property (nonatomic, retain) ListName *sharedList;
@property (nonatomic, retain) LightningAPI *lightningAPI;

@property (assign) NSObject <AddListViewControllerDelegate> *delegate;

- (void)doneAddList;
- (void)showLoadingView;

@end

@protocol AddListViewControllerDelegate <NSObject>

- (void)finishAddPrivateList:(NSString *)listName;
- (void)finishAddSharedList:(NSManagedObjectID *)objectID;

@end
