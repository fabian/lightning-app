//
//  MasterViewController.h
//  Lightning Push
//
//  Created by Cyril Gabathuler on 06.09.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ItemsViewController;

#import <CoreData/CoreData.h>
#import "AddListViewController.h"

@interface ListsViewController : UITableViewController <NSFetchedResultsControllerDelegate, AddListViewControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) ItemsViewController *itemsViewController;

@end
