//
//  ListViewController.h
//  Lightning
//
//  Created by Cyril Gabathuler on 15.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ListEntries.h"


@interface ListViewController : UITableViewController <UITextFieldDelegate> {
	ListEntries *listEntries;
	Boolean keyboardShown;
	UITableViewCell *activeCell;
}

- (void)registerForKeyboardNotifications;

@property (nonatomic, retain) ListEntries *listEntries;

@end
