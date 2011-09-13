//
//  LightningUtil.h
//  Lightning
//
//  Created by Cyril Gabathuler on 19.01.11.
//  Copyright 2011 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LightningUtil : NSObject {

}

+(NSString *)getUTCFormateDate:(NSDate *)localDate;
+(void)updateData:(NSManagedObjectContext *)context;

@end
