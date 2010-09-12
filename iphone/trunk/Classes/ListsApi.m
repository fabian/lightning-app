//
//  ListsApi.m
//  Lightning
//
//  Created by Cyril Gabathuler on 13.05.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import "ListsApi.h"
#import "Lightning.h"

@implementation ListsApi

@synthesize lightning;

- (void)intitWithLightning:(Lightning *)lightningInit {
	self.lightning = lightningInit;
}

- (void)addListWithTitle:(NSString *)title {
	
	NSArray *keys = [NSArray arrayWithObjects:@"title", @"owner", nil];
	NSArray *values = [NSArray arrayWithObjects:title, @"52", nil];
	NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
	
	NSURL *url = [[NSURL alloc] initWithString:[[lightning.url absoluteString] stringByAppendingString:@"lists"]];
	
	ApiRequest *request = [[ApiRequest alloc] initWithURL:url andDevice:lightning.url];
	[request post:parameters];
}

@end
