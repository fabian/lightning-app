//
//  ListsApi.h
//  Lightning
//
//  Created by Cyril Gabathuler on 13.05.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Lightning.h"


@interface ListsApi : NSObject {

	Lightning *lightning;
}

@property (nonatomic, retain) Lightning *lightning;

- (void)addListWithTitle:(NSString *)title;
- (void)intitWithLightning:(Lightning *)lightning;

@end
