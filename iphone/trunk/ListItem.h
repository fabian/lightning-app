//
//  ListItem.h
//  Lightning
//
//  Created by Cyril Gabathuler on 02.09.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ListName;

@interface ListItem : NSManagedObject

@property (nonatomic, retain) NSNumber * done;
@property (nonatomic, retain) NSNumber * listItemId;
@property (nonatomic, retain) NSString * creation;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * modified;
@property (nonatomic, retain) ListName *listName;

@end
