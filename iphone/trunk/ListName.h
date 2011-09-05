//
//  ListName.h
//  Lightning
//
//  Created by Cyril Gabathuler on 02.09.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ListItem;

@interface ListName : NSManagedObject

@property (nonatomic, retain) NSNumber * listId;
@property (nonatomic, retain) NSNumber * shared;
@property (nonatomic, retain) NSNumber * unreadCount;
@property (nonatomic, retain) NSString * token;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * lastModified;
@property (nonatomic, retain) NSSet *listItems;
@end

@interface ListName (CoreDataGeneratedAccessors)

- (void)addListItemsObject:(ListItem *)value;
- (void)removeListItemsObject:(ListItem *)value;
- (void)addListItems:(NSSet *)values;
- (void)removeListItems:(NSSet *)values;

@end
