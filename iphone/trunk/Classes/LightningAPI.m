//
//  LightningAPI.m
//  Lightning
//
//  Created by Cyril Gabathuler on 15.08.11.
//  Copyright (c) 2011 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import "LightningAPI.h"
#import "GTMHTTPFetcher.h"
#import "JSON.h"
#import "Device.h"
#import "ListName.h"
#import "ListItem.h"
#import "LightningUtil.h"

@implementation LightningAPI

@synthesize context = _context;
@synthesize lightningId = _lightningId;
@synthesize lightningSecret = _lightningSecret;
@synthesize apiURL = _apiURL;
@synthesize deviceToken = _deviceToken;
@synthesize username = _username;
@synthesize uniqueIdentifier = _uniqueIdentifier;
@synthesize delegate = _delegate;
@synthesize addListDelegate = _addListDelegate;

NSString * const prod = @"https://lightning-app.appspot.com/api/";
NSString * const dev = @"http://localhost:8080/api/";
NSString * const env = @"development";//production

+ (LightningAPI*) sharedManager {
    __strong static LightningAPI *lightnigAPI = nil;
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        lightnigAPI = [[self alloc] init];
    });
    return lightnigAPI;
}

- (void)initLightningWithContext:(NSManagedObjectContext *)context deviceToken:(NSString *)deviceToken  {
    NSLog(@"singleton test environment: %@", env);
    
    //setting the url according to the environment
    if([env isEqualToString:@"development"]) {
        self.apiURL = [NSURL URLWithString:dev];
    } else {
        self.apiURL = [NSURL URLWithString:prod];
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    //Setting the context for CoreData
    self.context = context;
    
    //Setting the deviceToken for push
    self.deviceToken = deviceToken;
    
    //Setting the uniqueIdentifier
    self.uniqueIdentifier = [userDefaults objectForKey:@"uniqueIdentifier"];        
    
    //Setting the username
    self.username = [userDefaults objectForKey:@"username"];
    
    //Checking if this is the very first time
    self.lightningId = [userDefaults valueForKey:@"lightningId"];
    self.lightningSecret = [userDefaults valueForKey:@"lightningSecret"];
    
    NSLog(@"lighntingId UserDefaults %@ and secret %@", self.lightningId, self.lightningSecret);
    
    if(self.lightningId == nil || self.lightningSecret == nil) {
        [self setupDevice];
    }
}

#pragma mark request

- (void)setupDevice {
    NSURL *callUrl = [[NSURL alloc] initWithString:[[self.apiURL absoluteString] stringByAppendingString:@"devices"]];
    
    NSLog(@"calling Url: %@", [callUrl description]);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:callUrl];
    
    [self prepareRequest:request device:false];
    
    //Getting and setting the uuid
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    NSString *uniqueIdentifier = (NSString *)CFUUIDCreateString(NULL, uuidRef);
    self.uniqueIdentifier = uniqueIdentifier;
    
    
    NSString * tokenAsString = [[[self.deviceToken description] 
                                 stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] 
                                stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *postString = [NSString stringWithFormat:@"device_token=%@;name=%@;identifier=%@", 
                                [tokenAsString uppercaseString],
                                self.username, 
                                self.uniqueIdentifier];
    

    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    GTMHTTPFetcher *myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
    [GTMHTTPFetcher setLoggingEnabled:YES];

    [myFetcher beginFetchWithDelegate:self
                    didFinishSelector:@selector(myFetcher:finishedSetupDevice:error:)];
}

-(void)getLists {
    if(self.lightningId != NULL) {
        NSURL *callUrl = [[NSURL alloc] initWithString:[[self.apiURL absoluteString] stringByAppendingFormat:@"devices/%@/lists", self.lightningId]];
    
        NSLog(@"calling Url: %@", [callUrl description]);

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:callUrl];
	
        [self prepareRequest:request device:true];
	
        GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
        [GTMHTTPFetcher setLoggingEnabled:YES];
        
        [myFetcher beginFetchWithDelegate:self
                        didFinishSelector:@selector(myFetcher:finishedWithGetLists:error:)];
    }
}

-(void)getItemsFromList:(NSString *)listId {
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.apiURL absoluteString] stringByAppendingFormat:@"lists/%@", listId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:callUrl];
	
    [self prepareRequest:request device:true];
	
	GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedGetItemsFromList:error:)];
	
}

-(void)addList:(NSString *)listTitle {
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.apiURL absoluteString] stringByAppendingFormat:@"lists?secret=%@", self.lightningSecret]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:callUrl];
	
    [self prepareRequest:request device:true];
	
    NSString * tokenAsString = [[[self.deviceToken description] 
                                 stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] 
                                stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *postString = [NSString stringWithFormat:@"title=%@;owner=%@", listTitle, self.lightningId];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];

    GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
    
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedAddList:error:)];
}

-(void)updateDevice:(NSString *)updatedDeviceToken Name:(NSString *)updatedName {
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.apiURL absoluteString] stringByAppendingFormat:@"devices/%@", self.lightningId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:callUrl];
	
    [self prepareRequest:request device:true];
	
	NSString * tokenAsString = [[[updatedDeviceToken description] 
								 stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] 
								stringByReplacingOccurrencesOfString:@" " withString:@""];
	
	NSString *putString = [NSString stringWithFormat:@"identifier=%@;name=%@;device_token=%@", self.uniqueIdentifier, updatedName, [tokenAsString uppercaseString]];
	
    [request setHTTPMethod:@"PUT"];
    [request setHTTPBody:[putString dataUsingEncoding:NSUTF8StringEncoding]];
	
    GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
    
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishUpdateDevice:error:)];
	
}

- (void)updateItem:(ListItem *)listItem {
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.apiURL absoluteString] stringByAppendingFormat:@"items/%@", listItem.listItemId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:callUrl];
	
    [self prepareRequest:request device:true];
	
	NSString *putString = [NSString stringWithFormat:@"value=%@;done=%@;modified=%@", listItem.name, listItem.done, listItem.modified];
	
	[request setHTTPMethod:@"PUT"];
    [request setHTTPBody:[putString dataUsingEncoding:NSUTF8StringEncoding]];
	//[myFetcher setEnvironment:environment_];
    
    GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedUpdateItem:error:)];
	
}

- (void)addItemToList:(NSNumber *)listId item:(ListItem *)item {
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.apiURL absoluteString] stringByAppendingFormat:@"items?secret=%@", self.lightningSecret]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:callUrl];
	
    [self prepareRequest:request device:true];
	
	NSString *postString = [NSString stringWithFormat:@"value=%@;list=%@", item.name, [listId stringValue]];
		
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	[myFetcher setUserData:[item objectID]];
	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedAddItemToList:error:)];
    
}

- (void)pushUpdateForList:(NSNumber *)listId {
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.apiURL absoluteString] stringByAppendingFormat:@"lists/%@/devices/%@/push", listId, self.lightningId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:callUrl];
	
    [self prepareRequest:request device:true];
		
	NSString *postString = [NSString stringWithFormat:@""];
    
	[request setHTTPMethod:@"POST"];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];

	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedPushForList:error:)];
}

#pragma mark responses
- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedSetupDevice:(NSData *)retrievedData error:(NSError *)error {
    if (error != nil) {
		int status = [error code];
		NSLog(@"error creating device: %i", status);
	} else {
        NSLog(@"finished setupDevice: %@", [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding]);
        
        NSString *data = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];
		SBJSON *parser = [[SBJSON alloc] init];
		NSDictionary *object = [parser objectWithString:data error:nil];
		self.lightningSecret = [object objectForKey:@"secret"];
		self.lightningId = [object objectForKey:@"id"];
		
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setValue:self.lightningId forKey:@"lightningId"];
		[userDefaults setValue:self.lightningSecret forKey:@"lightningSecret"];
        [userDefaults setValue:self.uniqueIdentifier forKey:@"uniqueIdentifier"];
		
		NSError *error;
		Device *newDevice = [NSEntityDescription insertNewObjectForEntityForName:@"Device" inManagedObjectContext:self.context];
		newDevice.deviceName = [object objectForKey:@"name"];;
		newDevice.deviceIdentifier = self.uniqueIdentifier;
		newDevice.lightningId = [NSString stringWithFormat:@"%@", self.lightningId];
		newDevice.lightningSecret = [NSString stringWithFormat:@"%@", self.lightningSecret];
		
		[self.context save:&error];
    }

}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedGetLists:(NSData *)retrievedData error:(NSError *)error {
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with getLists: %i", status);
		
		//calling the delegate eitherwise, so the coredata data can be displayed
		[self.delegate finishGetLists];
	} else {
		NSLog(@"getLists response %@", [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease]);
		
		NSString *data = [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease];
		SBJSON *parser = [[SBJSON alloc] init];
		NSDictionary *object = [parser objectWithString:data error:nil];
		NSArray *arrayOfList = [object objectForKey:@"lists"];
		
		[parser release];
		
		//check if list were delete
		//check if new list were added
		//update the list
		
		
		if ([arrayOfList count] == 0) {
			NSEntityDescription    * entity   = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.context];
			
			NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
			[fetch setEntity: entity];
			
			NSArray * results = [self.context executeFetchRequest:fetch error:nil];
			[fetch release];
			
			for (NSManagedObject *managedObject in results) {
				[self.context deleteObject:managedObject];
			}
			
		} else {
			//Version1
			NSEntityDescription * entity   = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.context];
			
			NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
			[fetch setEntity: entity];
			
			NSArray * results = [self.context executeFetchRequest:fetch error:nil];
			[fetch release];
			
			for (ListName *listName in results) {
				BOOL isListExists = FALSE;
				NSDictionary *list = nil;
				for (list in arrayOfList) {
					//NSLog(@"checking update google id %@ core")
					if ([[list objectForKey:@"id"] isEqual:[listName listId]]) {
						//update
						isListExists = TRUE;
						NSLog(@"update list");
						
						ListName *updatedList = listName;
						
						updatedList.name = [list objectForKey:@"title"];
						updatedList.listId = [list objectForKey:@"id"];
						updatedList.unreadCount = [list objectForKey:@"unread"];
						updatedList.token = [list objectForKey:@"token"];
						
						[self.context save:&error];
                        //TODO
						[self getItemsFromList:[list objectForKey:@"id"]];
					} 
				}
				if(!isListExists) {
					//list is not existing
					if ([results count] > [arrayOfList count]) {
						//delete list
						NSLog(@"delete List");
						
						[self.context deleteObject:listName];
					} else {
						//add list
						NSLog(@"creating List");
						
						ListName *listName = nil;
						
						listName = [NSEntityDescription insertNewObjectForEntityForName:@"ListName" inManagedObjectContext:self.context];
						listName.name = [list objectForKey:@"title"];
						listName.listId = [list objectForKey:@"id"];
						listName.token = [list objectForKey:@"token"];
						listName.lastModified = [LightningUtil getUTCFormateDate:[NSDate date]];
						
						[self.context save:&error];
					}
					
				} 
                
			}
			if ([arrayOfList count] > [results count]) {
                //go through listitems
                //check if listId = id
                //if result is 0 add list
				for (NSDictionary *list in arrayOfList) {
					
					NSEntityDescription *entity   = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.context];
					NSPredicate * predicate;
					predicate = [NSPredicate predicateWithFormat:@"listId == %@", [list objectForKey:@"id"]];
					
					NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
					[fetch setEntity: entity];
					[fetch setPredicate: predicate];
					
					NSArray * results = [self.context executeFetchRequest:fetch error:nil];
					[fetch release];
					
					if ([results count] == 0) {
						//add list
						NSLog(@"creating List");
						
						ListName *listName;
                        
                        listName = [NSEntityDescription insertNewObjectForEntityForName:@"ListName" inManagedObjectContext:self.context];
                        listName.name = [list objectForKey:@"title"];
                        listName.listId = [list objectForKey:@"id"];
                        listName.token = [list objectForKey:@"token"];
                        listName.lastModified = [LightningUtil getUTCFormateDate:[NSDate date]];
                        
                        [self.context save:&error];
					}
				}
			}
		}
		
		[self.delegate finishGetLists];
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedGetItemsFromList:(NSData *)retrievedData error:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with getItemsFromList: %i", status);
		
	} else {
		NSLog(@"getItemsFromList response %@", [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease]);
		
		NSString *data = [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease];
		SBJSON *parser = [[SBJSON alloc] init];
		NSDictionary *object = [parser objectWithString:data error:nil];
		
		[parser release];
		
		NSString *listId = [object objectForKey:@"id"];
		//Getting acutal List
		NSEntityDescription *entity   = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.context];
		NSPredicate * predicate;
		predicate = [NSPredicate predicateWithFormat:@"listId == %@", listId];
		
		NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
		[fetch setEntity: entity];
		[fetch setPredicate: predicate];
		
		NSArray * results = [self.context executeFetchRequest:fetch error:nil];
		[fetch release];
		
		if([results count] == 0) {
			NSLog(@"Something went wrong with CoreData");
		} else {
			ListName *listName = [results objectAtIndex:0];
			
			NSArray *arrayOfItems = [object objectForKey:@"items"];
			
			if ([arrayOfItems count] == 0) {
				//TODO doe this work?
				listName.listItems = nil;
				[self.context save:&error];
				
			} else {
				NSMutableArray *listItems = [[listName listItems] mutableCopy];
				NSMutableDictionary *listItemsWithKeysCoreData = [NSMutableDictionary dictionaryWithCapacity:[listItems count]];
				
				for (ListItem *listItem in listItems) {
					[listItemsWithKeysCoreData setValue:listItem forKey:[listItem.listItemId stringValue]];
				}
				
				//check if id is existing
				//update
				//check if we have to add or delete not existing item
				for (NSDictionary *listItemGoogle in arrayOfItems) {
					NSString *listId = [listItemGoogle objectForKey:@"id"];
					
					if ([listItemsWithKeysCoreData objectForKey:listId]) {
						if ([listItems count] > [arrayOfItems count]) {
							NSLog(@"delete item");
							ListItem *listItem = [listItemsWithKeysCoreData objectForKey:listId];
							[self.context deleteObject:listItem];
						} else {
							NSLog(@"listitem update");
							ListItem *listItem = [listItemsWithKeysCoreData objectForKey:listId];
							listItem.name = [listItemGoogle objectForKey:@"value"];
							listItem.listItemId = [listItemGoogle objectForKey:@"id"];
							listItem.done = [NSNumber numberWithBool:[[listItemGoogle objectForKey:@"done"] boolValue]];
							listItem.modified = [listItemGoogle objectForKey:@"modified"];
						}
					} else {
						NSLog(@"listitem add");
						ListItem *listItem = [NSEntityDescription insertNewObjectForEntityForName:@"ListItem" inManagedObjectContext:self.context];
						listItem.name = [listItemGoogle objectForKey:@"value"];
						listItem.listItemId = [listItemGoogle objectForKey:@"id"];
						listItem.done = [NSNumber numberWithBool:[[listItemGoogle objectForKey:@"done"] boolValue]];
						listItem.modified = [listItemGoogle objectForKey:@"modified"];
						listItem.creation = [listItemGoogle objectForKey:@"modified"];
                        
						[listName addListItemsObject:listItem];
					}
					
					[self.context save:&error];
				}
			}
		}
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedAddList:(NSData *)retrievedData error:(NSError *)error {
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with creating list: %i", status);
	} else {
		NSString *data = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];
		SBJSON *parser = [[SBJSON alloc] init];
		NSDictionary *list = [parser objectWithString:data error:nil];
		
		[parser release];
		ListName *listName;
		
		listName = [NSEntityDescription insertNewObjectForEntityForName:@"ListName" inManagedObjectContext:self.context];
		NSLog(@"%@, %@, %@", [list objectForKey:@"title"], [list objectForKey:@"id"], [list objectForKey:@"token"]);
		listName.name = [list objectForKey:@"title"];
		listName.listId = (NSNumber *)[list objectForKey:@"id"];
		listName.token = [list objectForKey:@"token"];
		listName.lastModified = [LightningUtil getUTCFormateDate:[NSDate date]];
		
		NSError* error;
        if(![self.context save:&error]) {
			NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
			NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
			if(detailedErrors != nil && [detailedErrors count] > 0) {
				for(NSError* detailedError in detailedErrors) {
					NSLog(@"  DetailedError: %@", [detailedError userInfo]);
				}
			}
			else {
				NSLog(@"  %@", [error userInfo]);
			}
        }
		[self.addListDelegate finishAddList:listName.token];
		
		NSLog(@"created a list with response %@", [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease]);
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishUpdateDevice:(NSData *)retrievedData error:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with finishUpdateDevice: %i", status);
		
	} else {
        //TODO implement
		NSLog(@"finishUpdateDevice %@", [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease]);
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedUpdateItem:(NSData *)retrievedData error:(NSError *)error {	
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with finishedUpdateItem: %i", status);
		
	} else {
		NSLog(@"finishedUpdateItem %@", [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease]);
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedAddItemToList:(NSData *)retrievedData error:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with creating item on list: %i", status);
	} else {
		NSLog(@"created an item with response %@", [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease]);
		
		NSString *data = [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease];
		SBJSON *parser = [[SBJSON alloc] init];
		NSDictionary *object = [parser objectWithString:data error:nil];
		
	    ListItem *item = (ListItem *)[self.context objectWithID:fetcher.userData];
    
        if(item != NULL) {
            item.name = [object objectForKey:@"value"];
            item.listItemId = [object objectForKey:@"id"];
            [self.context save:&error];
        }
        		
    }
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedPushForList:(NSData *)retrievedData error:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with push to list: %i", status);
	} else {
		NSLog(@"pushed update to list response %@", [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease]);
	}
}

#pragma mark helper methodes

- (void)prepareRequest:(NSMutableURLRequest *) request device:(Boolean)device {
    if(device) {
        NSString *deviceHeader = [NSString stringWithFormat:@"%@devices/%@?secret=%@", self.apiURL, self.lightningId, self.lightningSecret];
        [request addValue:deviceHeader forHTTPHeaderField:@"Device"];
    }
    
    [request addValue:env forHTTPHeaderField:@"Environment"];
}

- (void)ping {
    
}

@end
