//
//  Device.h
//  Lightning Push
//
//  Created by Cyril Gabathuler on 06.09.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Device : NSManagedObject

@property (nonatomic, retain) NSString * deviceIdentifier;
@property (nonatomic, retain) NSString * deviceName;
@property (nonatomic, retain) NSString * lightningSecret;
@property (nonatomic, retain) NSString * lightningId;

@end
