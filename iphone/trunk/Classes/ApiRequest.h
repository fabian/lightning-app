//
//  ApiRequest.h
//  Lightning
//
//  Created by Fabian on 3/16/10.
//  Copyright 2010 Liip AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApiRequest : NSObject {
	
@private
	NSMutableData *data;
    NSURL *url;
    NSString *device;
    NSURLConnection *connection;
}

@property (nonatomic, readonly) NSData *data;
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *device;

- (NSString *)reponse;
- (id)initWithURL:(NSURL *)url;
- (id)initWithURL:(NSURL *)url andDevice:(NSString *)device;
- (void)post:(NSDictionary *)parameters;
- (void)get;

@end
