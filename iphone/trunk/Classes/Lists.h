//
//  Lists.h
//  Lightning
//
//  Created by Cyril Gabathuler on 15.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <Foundation/Foundation.h>
#import	"ListEntries.h";

@interface Lists : NSObject {
	
	NSMutableArray *lists;
	NSString *title;

}

-(unsigned)countOfList;
-(ListEntries *)listEntriesAtIndex:(unsigned)i;
-(NSString *)titleOfListAtIndex:(unsigned)i;

@property (nonatomic, retain) NSMutableArray *lists;
@property (nonatomic, retain) NSString *title;

@end
