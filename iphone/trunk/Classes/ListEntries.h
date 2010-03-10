//
//  List.h
//  Lightning
//
//  Created by Cyril Gabathuler on 15.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ListEntries : NSObject {
	NSString *title;
	NSMutableArray *entries;
}


@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSMutableArray *entries;

@end
