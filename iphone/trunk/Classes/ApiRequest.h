//
//  ApiRequest.h
//  Lightning
//
//  Created by Fabian on 3/16/10.
//  Copyright 2010 Liip AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ApiRequestDelegate;

@interface ApiRequest : NSObject {
	
@private
	NSMutableData *data;
    NSURL *url;
    NSString *device;
    NSURLConnection *connection;
	id <ApiRequestDelegate> delegate;	
	
}

@property (nonatomic, readonly) NSData *data;
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *device;
@property (assign) id <ApiRequestDelegate> delegate;

- (NSString *)reponse;
- (id)initWithURL:(NSURL *)url;
- (id)initWithURL:(NSURL *)url andDevice:(NSString *)device;
- (void)post:(NSDictionary *)parameters;
- (void)get;

@end

@protocol ApiRequestDelegate <NSObject>

- (void)reloadData:(NSDictionary *)data;

@end
