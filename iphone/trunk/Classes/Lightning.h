//
//  Lightning.h
//  Lightning
//
//  Created by Fabian on 3/16/10.
//  Copyright 2010 Liip AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ListItem.h"


@protocol LightningDelegate;

@interface Lightning : NSObject {
	
    NSURL *url;
	NSString *device;
	NSData *deviceToken;
	NSString *lightningId;
	NSString *lightningSecret;
	NSManagedObjectContext *context;
	
	id <LightningDelegate> delegate;	
}

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSString *device;
@property (nonatomic, retain) NSData *deviceToken;
@property (nonatomic, retain) NSString *lightningId;
@property (nonatomic, retain) NSString *lightningSecret;
@property (retain, nonatomic) NSManagedObjectContext *context;

@property (assign) id <LightningDelegate> delegate;

- (id)initWithURL:(NSURL *)initUrl andDeviceToken:(NSString *)initDeviceToken username:(NSString *)username;
- (id)initWithURL:(NSURL *)url andDevice:(NSString *)device;
- (void)addListWithTitle:(NSString *)listTitle context:(NSManagedObjectContext *)context;
- (void)getLists;
- (void)getListsWithContext:(NSManagedObjectContext *)context;

-(void)getLists;
-(void)addItemToList:(NSString *)listId item:(ListItem *)item context:(NSManagedObjectContext *)context;
-(void)shareList:(NSString *)listId token:(NSString *)token;
-(void)updateItem:(ListItem *)listItem;

@end

@protocol LightningDelegate <NSObject>

- (void)finishFetchingLists:(NSData *)data;
- (void)finishAddingList:(NSManagedObjectID *)objectID;

@end