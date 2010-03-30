//
//  ApiRequest.m
//  Lightning
//
//  Created by Fabian on 3/16/10.
//  Copyright 2010 Liip AG. All rights reserved.
//

#import "ApiRequest.h"
#import "JSON.h"

@implementation ApiRequest

@synthesize data, url, device;

- (id)initWithURL:(NSURL *)url {
    
	if(self = [super init]) {
		data = [[NSMutableData alloc] init];
		self.url = url;
		device = nil;
		connection = nil;
    }
	
    return self;
}

- (id)initWithURL:(NSURL *)url andDevice:(NSString *)device {
    
	if(self = [super init]) {
		data = [[NSMutableData alloc] init];
		self.url = url;
		self.device = device;
		connection = nil;
    }
	
    return self;
}

- (void)dealloc {
    [data release];
    data = nil;
	[url release];
	[device release];
    [super dealloc];
}

- (void)cancelConnection {
    [connection cancel];
    [connection release];
    connection = nil;
}

- (void)post:(NSDictionary *)parameters {
	
	NSString *mimeType = @"text/html";
	NSMutableString *params = [[NSMutableString alloc] init];
	for (id key in parameters) {
		NSString *encodedKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		CFStringRef value = (CFStringRef)[[parameters objectForKey:key] copy];
		// Escape even the "reserved" characters for URLs 
		// as defined in http://www.ietf.org/rfc/rfc2396.txt
		CFStringRef encodedValue = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, value, NULL, (CFStringRef)@";/?:@&=+$,", kCFStringEncodingUTF8);
		[params appendFormat:@"%@=%@&", encodedKey, encodedValue];
		CFRelease(value);
		CFRelease(encodedValue);
	}
	[params deleteCharactersInRange:NSMakeRange([params length] - 1, 1)];
	
	NSString *contentType = @"application/x-www-form-urlencoded; charset=utf-8";
	NSData *body = [params dataUsingEncoding:NSUTF8StringEncoding];
	
	NSMutableDictionary* headers = [[[NSMutableDictionary alloc] init] autorelease];
	[headers setValue:contentType forKey:@"Content-Type"];
	[headers setValue:mimeType forKey:@"Accept"];
	[headers setValue:@"no-cache" forKey:@"Cache-Control"];
	[headers setValue:@"no-cache" forKey:@"Pragma"];
	[headers setValue:@"close" forKey:@"Connection"]; // Avoid HTTP 1.1 "keep alive" for the connection
	if (self.device != nil) {
		[headers setValue:self.device forKey:@"Device"];
	}
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	[request setHTTPMethod:@"POST"];
	[request setAllHTTPHeaderFields:headers];
	[request setHTTPBody:body];
	[params release];
	
	[self cancelConnection];
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

- (void)get:(NSDictionary *)parameters {
	
	NSString *mimeType = @"text/html";
	NSMutableString *params = [[NSMutableString alloc] init];
	for (id key in parameters) {
		NSString *encodedKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		CFStringRef value = (CFStringRef)[[parameters objectForKey:key] copy];
		// Escape even the "reserved" characters for URLs 
		// as defined in http://www.ietf.org/rfc/rfc2396.txt
		CFStringRef encodedValue = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, value, NULL, (CFStringRef)@";/?:@&=+$,", kCFStringEncodingUTF8);
		[params appendFormat:@"%@=%@&", encodedKey, encodedValue];
		CFRelease(value);
		CFRelease(encodedValue);
	}
	[params deleteCharactersInRange:NSMakeRange([params length] - 1, 1)];
	
	NSString *contentType = @"application/x-www-form-urlencoded; charset=utf-8";
	
	NSMutableDictionary* headers = [[[NSMutableDictionary alloc] init] autorelease];
	[headers setValue:contentType forKey:@"Content-Type"];
	[headers setValue:mimeType forKey:@"Accept"];
	[headers setValue:@"no-cache" forKey:@"Cache-Control"];
	[headers setValue:@"no-cache" forKey:@"Pragma"];
	[headers setValue:@"close" forKey:@"Connection"]; // Avoid HTTP 1.1 "keep alive" for the connection
	if (self.device != nil) {
		[headers setValue:self.device forKey:@"Device"];
	}
	
	NSString *urlWithParams = [[url absoluteString] stringByAppendingFormat:@"?%@", params];
	NSURL *finalURL = [NSURL URLWithString:urlWithParams];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:finalURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	[request setHTTPMethod:@"GET"];
	[request setAllHTTPHeaderFields:headers];
	
	[self cancelConnection];
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

- (NSString *)response {
    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    
	NSLog(@"Status code: %i", [httpResponse statusCode]);
    [data setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self cancelConnection];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self cancelConnection];
	NSLog(@"Response: %@", [self response]);
	
	SBJSON *parser = [[SBJSON alloc] init];
	NSDictionary *object = [parser objectWithString:[self response] error:nil];
	NSLog(@"Response: %@", [object objectForKey:@"title"]);
    
}


@end
