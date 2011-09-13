//
//  Line.m
//  Lightning
//
//  Created by Cyril Gabathuler on 27.01.11.
//  Copyright 2011 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import "Line.h"


@implementation Line


- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef c = UIGraphicsGetCurrentContext();
	
    CGContextSetRGBStrokeColor(c, 0.7f, 0.0f, 0.0f, 1.0f);
	CGContextSetLineWidth(c, 3.0f);
	CGContextMoveToPoint(c, self.bounds.origin.x, self.bounds.origin.y);
	CGContextAddLineToPoint(c, self.bounds.size.width, self.bounds.origin.y);

    CGContextStrokePath(c);
}

@end
