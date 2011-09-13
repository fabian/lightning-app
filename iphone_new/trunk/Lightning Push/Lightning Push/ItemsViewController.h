//
//  ItemsViewController.h
//  Lightning Push
//
//  Created by Cyril Gabathuler on 06.09.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ListName.h"
#import "ListItem.h"
#import "Line.h"
#import "LightningUtil.h"
#import "LightningAPI.h"

@interface ItemsViewController : UITableViewController <NSFetchedResultsControllerDelegate, UITextFieldDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) ListName *listName;
@property (strong, nonatomic) LightningAPI *lightningAPI;
@property (strong, nonatomic) NSTimer *timer;

@end
