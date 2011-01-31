//
//  Device.h
//  Lightning
//
//  Created by Cyril Gabathuler on 31.01.11.
//  Copyright 2011 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface Device :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * deviceName;
@property (nonatomic, retain) NSString * deviceIdentifier;

@end



