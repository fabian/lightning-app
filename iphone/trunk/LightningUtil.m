//
//  LightningUtil.m
//  Lightning
//
//  Created by Cyril Gabathuler on 19.01.11.
//  Copyright 2011 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import "LightningUtil.h"
#import "LightningAPI.h"
#import "Lightning.h"


@implementation LightningUtil

+(NSString *)getUTCFormateDate:(NSDate *)localDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:localDate];
	
    return dateString;
}

+(void)updateData:(NSManagedObjectContext *)context navigationController:(UINavigationController *)navigationController {
	LightningAPI *lightningAPI = [LightningAPI sharedManager];
    lightningAPI.delegate = [[navigationController viewControllers] objectAtIndex:0];
    [lightningAPI getLists];
}

@end
