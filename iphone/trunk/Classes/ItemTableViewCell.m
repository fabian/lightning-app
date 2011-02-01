//
//  ItemTableViewCell.m
//  Lightning
//
//  Created by Cyril Gabathuler on 01.02.11.
//  Copyright 2011 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import "ItemTableViewCell.h"


@implementation ItemTableViewCell

@synthesize indexPath;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code.
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state.
}


- (void)dealloc {
    [super dealloc];
	[indexPath release];
}


@end
