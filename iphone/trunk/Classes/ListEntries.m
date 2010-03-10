//
//  List.m
//  Lightning
//
//  Created by Cyril Gabathuler on 15.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import "ListEntries.h"


@implementation ListEntries

@synthesize title, entries;

- (void)dealloc {
	[title release];
	[entries release];
    [super dealloc];
}

@end
