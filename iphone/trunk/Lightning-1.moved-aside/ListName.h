//
//  ListName.h
//  Lightning
//
//  Created by Cyril Gabathuler on 02.04.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface ListName :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * id;

@end



