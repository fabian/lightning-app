//
//  ListItem.h
//  Lightning Push
//
//  Created by Cyril Gabathuler on 06.09.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ListItem : NSManagedObject

@property (nonatomic, retain) NSString * creation;
@property (nonatomic, retain) NSNumber * done;
@property (nonatomic, retain) NSNumber * listItemId;
@property (nonatomic, retain) NSString * modified;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSManagedObject *listName;

@end
