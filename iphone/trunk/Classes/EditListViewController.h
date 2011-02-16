//
//  EditListViewController.h
//  Lightning
//
//  Created by Cyril Gabathuler on 16.02.11.
//  Copyright 2011 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "ListName.h";


@interface EditListViewController : UITableViewController {

	UIView *footerView;
	NSManagedObjectContext *context;
	ListName *list;
}

@property (nonatomic, retain) NSManagedObjectContext *context;
@property (nonatomic, retain) ListName *list;

- (id)initWithStyle:(UITableViewStyle)style context:(NSManagedObjectContext *)context_ list:(ListName *)list_;

@end
