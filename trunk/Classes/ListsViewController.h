//
//  ListsViewController.h
//  Lightning
//
//  Created by Cyril Gabathuler on 15.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Lists.h";

#import <QuartzCore/QuartzCore.h>

@interface ListsViewController : UITableViewController {
	Lists *lists;
}

-(void) addList;

@property (nonatomic, retain) Lists *lists;

@end
