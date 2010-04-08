//
//  Lightning.m
//  Lightning
//
//  Created by Fabian on 3/16/10.
//  Copyright 2010 Liip AG. All rights reserved.
//

#import "Lightning.h"

@implementation Lightning

@synthesize url, device;

- (id)initWithURL:(NSURL *)url {
    
	if(self = [super init]) {
		
		self.url = url;
		
		NSArray *keys = [NSArray arrayWithObjects:@"name", @"identifier", nil];
		NSArray *values = [NSArray arrayWithObjects:@"Test iPhone", [UIDevice currentDevice].uniqueIdentifier, nil];
		NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
		
		NSURL *url = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingString:@"devices"]];
		
		ApiRequest *request = [[ApiRequest alloc] initWithURL:url];
		request.delegate = self;
		[request post:parameters];
    }
	
    return self;
}

- (id)initWithURL:(NSURL *)url andDevice:(NSString *)device {
    
	if(self = [super init]) {
		
		self.url = url;
		self.device = device;
    }
	
    return self;
}

- (void)dealloc {
    [url release];
	[device release];
    [super dealloc];
}

- (void)addListWithTitle:(NSString *)title {
	
	NSArray *keys = [NSArray arrayWithObjects:@"title", @"owner", nil];
	NSArray *values = [NSArray arrayWithObjects:title, @"52", nil];
	NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
	
	NSURL *url = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingString:@"lists"]];
	
	ApiRequest *request = [[ApiRequest alloc] initWithURL:url andDevice:device];
	[request post:parameters];
}

- (void)getLists {
	
	NSURL *url = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingString:@"lists"]];
	
	NSArray *keys = [NSArray arrayWithObjects:@"owner", nil];
	NSArray *values = [NSArray arrayWithObjects:@"4", nil];
	NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
	
	ApiRequest *request = [[ApiRequest alloc] initWithURL:url andDevice:device];
	[request get:parameters];
}

- (void) reloadData:(NSDictionary *)data {
	NSLog(@"delegate called IHAA");
}

@end
