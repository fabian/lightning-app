//
//  ShareListViewController.h
//  Lightning
//
//  Created by Cyril Gabathuler on 24.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddNewGroup.h";

@protocol AddListViewControllerDelegate;

@interface AddListViewController : UITableViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, AddNewGroupDelegate>{
	id <AddListViewControllerDelegate> delegate;
	NSIndexPath *indexPathCell1;
	NSIndexPath *indexPathCell2;
	UITextField *listName;
	int checkmark;
}

@property (nonatomic, retain) NSIndexPath *indexPathCell1;
@property (nonatomic, retain) NSIndexPath *indexPathCell2;
@property (nonatomic) int checkmark;
@property (nonatomic, retain) UITextField *listName;

@property (assign) id <AddListViewControllerDelegate> delegate;

- (void)doneAddList;

@end

@protocol AddListViewControllerDelegate <NSObject>

- (void)finishAddList:(int)checkmark andListName:(NSString *)listName;

@end
