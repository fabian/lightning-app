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
#import <CoreData/CoreData.h>
#import "ListName.h"
#import "LightningAPI.h"

@protocol AddListViewControllerDelegate;

@interface AddListViewController : UITableViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate, LightningAPIAddListDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic) int checkmark;
@property (strong, nonatomic) UITextField *listNameTextField;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) ListName *sharedList;
@property (strong, nonatomic) LightningAPI *lightningAPI;

@property (assign) NSObject <AddListViewControllerDelegate> *delegate;

- (void)doneAddList;
- (void)showLoadingView;

@end

@protocol AddListViewControllerDelegate <NSObject>

- (void)finishAddPrivateList:(NSString *)listName;
- (void)finishAddSharedList:(NSManagedObjectID *)objectID;

@end
