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

- (id)initWithURL:(NSURL *)initUrl andDeviceToken:(NSString *)initDeviceToken;
- (id)initWithURL:(NSURL *)url andDevice:(NSString *)device;
- (void)addListWithTitle:(NSString *)title;
- (void)getLists;
- (void)getListsWithContext:(NSManagedObjectContext *)context;

-(void)createListWithTitle:(NSString *)listTitle;
-(void)getLists;
-(void)addItemToList:(NSString *)listId item:(ListItem *)item context:(NSManagedObjectContext *)context;

@end

@protocol LightningDelegate <NSObject>

- (void)finishFetchingLists:(NSData *)data;

@end