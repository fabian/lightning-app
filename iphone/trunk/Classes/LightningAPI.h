//
//  LightningAPI.h
//  Lightning
//
//  Created by Cyril Gabathuler on 15.08.11.
//  Copyright (c) 2011 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ListItem.h"

@protocol LightningAPIListsDelegate;
@protocol LightningAPIAddListDelegate;
@protocol LightningAPIReadListDelegate;

@interface LightningAPI : NSObject


@property(nonatomic, retain) NSManagedObjectContext *context;
@property (nonatomic, retain) NSString *lightningId;
@property (nonatomic, retain) NSString *lightningSecret;
@property (nonatomic, retain) NSString *deviceToken;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *uniqueIdentifier;
@property (nonatomic, retain) NSURL *apiURL;
@property (assign) id <LightningAPIListsDelegate> delegate;
@property (assign) id <LightningAPIAddListDelegate> addListDelegate;
@property (assign) id <LightningAPIReadListDelegate> readListDelegate;

+ (LightningAPI*) sharedManager;

- (void)setupDevice;
- (void)initLightningWithContext:(NSManagedObjectContext *)context deviceToken:(NSString *)deviceToken;
- (void)prepareRequest:(NSMutableURLRequest *) request device:(Boolean)device;
- (void)updateDevice:(NSString *)updatedDeviceToken Name:(NSString *)updatedName;
- (void)getLists;
- (void)addList:(NSString *)listTitle;
- (void)updateItem:(ListItem *)listItem;
- (void)addItemToList:(NSNumber *)listId item:(ListItem *)item;
- (void)pushUpdateForList:(NSNumber *)listId;
- (void)readList:(NSString *)listId;
    
@end

@protocol LightningAPIListsDelegate <NSObject>

- (void)finishGetLists;

@end

@protocol LightningAPIAddListDelegate <NSObject>

- (void)finishAddList:(NSString *)token;

@end

@protocol LightningAPIReadListDelegate <NSObject>

- (void)finishReadList;

@end


