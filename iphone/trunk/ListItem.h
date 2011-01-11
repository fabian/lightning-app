//
//  ListItem.h
//  Lightning
//
//  Created by Cyril Gabathuler on 31.10.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface ListItem :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * creation;
@property (nonatomic, retain) NSNumber * listItemId;

@end



