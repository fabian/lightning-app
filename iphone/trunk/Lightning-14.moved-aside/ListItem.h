//
//  ListItem.h
//  Lightning
//
//  Created by Cyril Gabathuler on 27.01.11.
//  Copyright 2011 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface ListItem :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * done;
@property (nonatomic, retain) NSNumber * listItemId;
@property (nonatomic, retain) NSString * creation;
@property (nonatomic, retain) NSString * name;

@end



