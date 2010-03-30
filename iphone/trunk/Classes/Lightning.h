//
//  Lightning.h
//  Lightning
//
//  Created by Fabian on 3/16/10.
//  Copyright 2010 Liip AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Lightning : NSObject {
	
    NSURL *url;
	NSString *device;
}

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSString *device;

- (id)initWithURL:(NSURL *)url;
- (id)initWithURL:(NSURL *)url andDevice:(NSString *)device;
- (void)addListWithTitle:(NSString *)title;
- (void)getLists;

@end
