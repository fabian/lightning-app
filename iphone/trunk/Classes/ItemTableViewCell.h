//
//  ItemTableViewCell.h
//  Lightning
//
//  Created by Cyril Gabathuler on 01.02.11.
//  Copyright 2011 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ItemTableViewCell : UITableViewCell {
	NSIndexPath* indexPath;
	Boolean editingText;
}

@property (nonatomic, retain) NSIndexPath* indexPath;

@end
