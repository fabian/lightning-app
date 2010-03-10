//
//  Lists.m
//  Lightning
//
//  Created by Cyril Gabathuler on 15.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import "Lists.h"
#import "ListEntries.h"

@implementation Lists

@synthesize title;
@synthesize lists;

- (id)init {
	
	[self setTitle:@"Cyril"];
	NSMutableArray *listOfEntries = [[NSMutableArray alloc] init];
	
	NSMutableArray *entries = [[NSMutableArray alloc] init];
	[entries addObject:@"Entry1"];
	[entries addObject:@"Entry1"];
	[entries addObject:@"Entry1"];
	
	ListEntries *list = nil;

	list = [[ListEntries alloc] init];
	list.title = @"List1";
	list.entries = entries;
	[listOfEntries addObject:list];
	[list release];
	
	list = [[ListEntries alloc] init];
	list.title = @"List2";
	list.entries = entries;
	[listOfEntries addObject:list];
	[list release];
	
	list = [[ListEntries alloc] init];
	list.title = @"List3";
	list.entries = entries;
	[listOfEntries addObject:list];
	[list release];
	
	[entries release];
	
	self.lists = listOfEntries;
	
	return [super init];
}

- (unsigned)countOfList {
	return [lists count];
}

- (NSString *) titleOfListAtIndex:(unsigned)i {
	ListEntries *list = [lists objectAtIndex:i];
	NSLog(@"Test");
	
	return list.title;
	[list release];
}

-(ListEntries *)listEntriesAtIndex:(unsigned)i {
	return [lists objectAtIndex:i];
}

- (void)dealloc {
	[title release];
	[lists release];
    [super dealloc];
}


@end
