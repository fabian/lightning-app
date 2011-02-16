//
//  ListName.h
//  Lightning
//
//  Created by Cyril Gabathuler on 19.01.11.
//  Copyright 2011 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ListItem;

@interface ListName :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * lastModified;
@property (nonatomic, retain) NSNumber * listId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * unreadCount;
@property (nonatomic, retain) NSString * token;
@property (nonatomic, retain) NSSet* listItems;

@end


@interface ListName (CoreDataGeneratedAccessors)
- (void)addListItemsObject:(ListItem *)value;
- (void)removeListItemsObject:(ListItem *)value;
- (void)addListItems:(NSSet *)value;
- (void)removeListItems:(NSSet *)value;

@end

