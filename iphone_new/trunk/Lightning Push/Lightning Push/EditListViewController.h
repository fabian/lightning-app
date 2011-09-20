//
//  EditListViewController.h
//  Lightning
//
//  Created by Cyril Gabathuler on 16.02.11.
//  Copyright 2011 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "ListName.h"
#import "ListItem.h"
#import "LightningAPI.h"


@interface EditListViewController : UITableViewController<UIActionSheetDelegate, LightningAPIAddListDelegate, MFMailComposeViewControllerDelegate> 

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) ListName *listName;
@property (strong, nonatomic) UIView *footerDeleteView;
@property (strong, nonatomic) UIView *footerMailView;
@property (strong, nonatomic) LightningAPI *lightningAPI;

@end
