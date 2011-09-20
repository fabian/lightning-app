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
@synthesize readListDelegate = _readListDelegate;
@synthesize listName = _listName;


BOOL updateDeviceToken = FALSE;

NSString * const prod = @"https://lightning-app.appspot.com/api/";
NSString * const dev = @"http://localhost:8080/api/";//http://192.168.37.20:8080/api/
NSString * const env = @"development";//production

+ (LightningAPI*) sharedManager {
    __strong static LightningAPI *lightnigAPI = nil;
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        lightnigAPI = [[self alloc] init];
    });
    return lightnigAPI;
}

- (void)initLightningWithContext:(NSManagedObjectContext *)context {
    NSLog(@"singleton test environment: %@", env);
    
    //setting the url according to the environment
    if([env isEqualToString:@"development"]) {
        self.apiURL = [NSURL URLWithString:dev];
    } else {
        self.apiURL = [NSURL URLWithString:prod];
    }
   
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    //Setting the deviceToken for push
    self.deviceToken = [userDefaults objectForKey:@"deviceToken"];
    
    //Setting the uniqueIdentifier
    self.uniqueIdentifier = [userDefaults objectForKey:@"uniqueIdentifier"];        
    
    //Setting the context for CoreData
    self.context = context;
    
    #warning new method for username
    //Setting the username
    //self.username = [userDefaults objectForKey:@"username"];
    self.username = @"test";
    
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
    NSString *uniqueIdentifier = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    
    //Setting the uniqueIdentifier
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:uniqueIdentifier forKey:@"uniqueIdentifier"];        
    self.uniqueIdentifier = uniqueIdentifier;
    
    #warning device token will be there after the device has succesfully get one...move it to update device...
    NSString * tokenAsString = [[[self.deviceToken description] 
                                 stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] 
                                stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *postString = [NSString stringWithFormat:@"device_token=%@;name=%@;identifier=%@", 
                                self.deviceToken,
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
                        didFinishSelector:@selector(myFetcher:finishedGetLists:error:)];
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

-(void)addList:(NSString *)listTitle isShared:(Boolean)isShared{
    self.listName = [NSEntityDescription insertNewObjectForEntityForName:@"ListName" inManagedObjectContext:self.context];
    self.listName.name = listTitle;
    
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.apiURL absoluteString] stringByAppendingFormat:@"lists?secret=%@", self.lightningSecret]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:callUrl];
	
    [self prepareRequest:request device:true];
	
    //NSString * tokenAsString = [[[self.deviceToken description] 
  //                               stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] 
//                                stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *postString = [NSString stringWithFormat:@"title=%@;owner=%@;shared=%@", listTitle, self.lightningId, isShared?@"1":@"0"];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];

    GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
    
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedAddList:error:)];
}

-(void)updateDevice:(NSString *)updatedDeviceToken Name:(NSString *)updatedName {
    if (self.lightningId == nil) {
        updateDeviceToken = YES;
        self.deviceToken = updatedDeviceToken;
        return;
    }    
    
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.apiURL absoluteString] stringByAppendingFormat:@"devices/%@", self.lightningId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:callUrl];
	
    [self prepareRequest:request device:true];
	
	NSString * tokenAsString = [[[updatedDeviceToken description] 
								 stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] 
								stringByReplacingOccurrencesOfString:@" " withString:@""];

    NSLog(@"identifier=%@;name=%@;device_token=%@", self.uniqueIdentifier, updatedName, [tokenAsString uppercaseString]);
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
		
	//NSString *postString = [NSString stringWithFormat:@""];
    
	[request setHTTPMethod:@"POST"];
    //[request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];

	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedPushForList:error:)];
}

- (void)readList:(NSNumber *)listId {
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.apiURL absoluteString] stringByAppendingFormat:@"lists/%@/devices/%@/read", listId, self.lightningId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:callUrl];
	
    [self prepareRequest:request device:true];	
		
	[request setHTTPMethod:@"POST"];
	
    GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
    
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedReadList:error:)];
    
}

- (void)shareList:(NSString *)listId token:(NSString *)token {
    NSURL *callUrl = [[NSURL alloc] initWithString:[[self.apiURL absoluteString] stringByAppendingFormat:@"devices/%@/lists/%@", self.lightningId, listId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:callUrl];
    
    [self prepareRequest:request device:true];	
	
    NSString *putString = [NSString stringWithFormat:@"token=%@", token];
	
	[request setHTTPMethod:@"PUT"];
    [request setHTTPBody:[putString dataUsingEncoding:NSUTF8StringEncoding]];
	
    GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishShareList:error:)];
}

- (void)updateList:(ListName *)listName {
    self.listName = listName;
    
    NSURL *callUrl = [[NSURL alloc] initWithString:[[self.apiURL absoluteString] stringByAppendingFormat:@"lists/%@", self.listName.listId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:callUrl];
    
    [self prepareRequest:request device:true];	
	
    NSString *putString = [NSString stringWithFormat:@"title=%@&shared=%@", listName.name, [self.listName.shared stringValue]];
    NSLog(@"put string %@", putString);
	
	[request setHTTPMethod:@"PUT"];
    [request setHTTPBody:[putString dataUsingEncoding:NSUTF8StringEncoding]];
	
    GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishUpdateList:error:)];
}

- (void)deleteItem:(NSString *)itemId {
    NSURL *callUrl = [[NSURL alloc] initWithString:[[self.apiURL absoluteString] stringByAppendingFormat:@"items/%@", itemId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:callUrl];
    
    [self prepareRequest:request device:true];	
	
	[request setHTTPMethod:@"DELETE"];
	
    GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishDeleteItem:error:)];
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
        
        if(updateDeviceToken) {
            [self updateDevice:self.deviceToken Name:self.username];
        }
            
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
		NSLog(@"getLists response %@", [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding]);
		
		NSString *data = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];
		SBJSON *parser = [[SBJSON alloc] init];
		NSDictionary *object = [parser objectWithString:data error:nil];
		NSArray *arrayOfList = [object objectForKey:@"lists"];
		
		//check if list were delete
		//check if new list were added
		//update the list
		
		
		if ([arrayOfList count] == 0) {
			NSEntityDescription    * entity   = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.context];
			
			NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
			[fetch setEntity: entity];
			
			NSArray * results = [self.context executeFetchRequest:fetch error:nil];
			
			for (NSManagedObject *managedObject in results) {
				[self.context deleteObject:managedObject];
			}
			
		} else {
			//Version1
			NSEntityDescription * entity   = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.context];
			
			NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
			[fetch setEntity: entity];
			
			NSArray * results = [self.context executeFetchRequest:fetch error:nil];
			
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
						updatedList.token = [list objectForKey:@"token"];
                        updatedList.shared = [NSNumber numberWithBool:[(NSString *)[list objectForKey:@"shared"] boolValue]];
						//updatedList.unreadCount = [list objectForKey:@"unread"];
                        updatedList.hasUnread = [NSNumber numberWithBool:[(NSString *)[list objectForKey:@"unread"] boolValue]];
						
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
                        listName.shared = [NSNumber numberWithBool:[(NSString *)[list objectForKey:@"shared"] boolValue]];
						listName.unreadCount = 0;
                        listName.hasUnread = [NSNumber numberWithBool:[(NSString *)[list objectForKey:@"unread"] boolValue]];
						
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
					
					if ([results count] == 0) {
						//add list
						NSLog(@"creating List");
						
						ListName *listName;
                        
                        listName = [NSEntityDescription insertNewObjectForEntityForName:@"ListName" inManagedObjectContext:self.context];
                        listName.name = [list objectForKey:@"title"];
                        listName.listId = [list objectForKey:@"id"];
                        listName.token = [list objectForKey:@"token"];
                        listName.lastModified = [LightningUtil getUTCFormateDate:[NSDate date]];
                        listName.shared = [NSNumber numberWithBool:[(NSString *)[list objectForKey:@"shared"] boolValue]];
						listName.unreadCount = 0;
                        listName.hasUnread = [NSNumber numberWithBool:[(NSString *)[list objectForKey:@"unread"] boolValue]];
                        
                        [self.context save:&error];
					}
				}
			}
		}
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
		NSLog(@"getItemsFromList response %@", [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding]);
		
		NSString *data = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];
		SBJSON *parser = [[SBJSON alloc] init];
		NSDictionary *object = [parser objectWithString:data error:nil];
		
		NSString *listId = [object objectForKey:@"id"];
		//Getting acutal List
		NSEntityDescription *entity   = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.context];
		NSPredicate * predicate;
		predicate = [NSPredicate predicateWithFormat:@"listId == %@", listId];
		
		NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
		[fetch setEntity: entity];
		[fetch setPredicate: predicate];
		
		NSArray * results = [self.context executeFetchRequest:fetch error:nil];
		
		if([results count] == 0) {
			NSLog(@"Something went wrong with CoreData");
		} else {
			ListName *listName = [results objectAtIndex:0];
			
			NSArray *arrayOfItems = [object objectForKey:@"items"];
            
            //check if existing
            //add
            //update
            //delete
          	
			if ([arrayOfItems count] == 0) {
				//TODO doe this work?
				listName.listItems = nil;
				[self.context save:&error];
				
			} else {
                NSMutableSet *itemsToUpdate = [[NSMutableSet alloc] init];
                NSMutableArray *itemsToAdd = [[NSMutableArray alloc] init];
                
                
                for(NSDictionary *item in arrayOfItems) {
                    NSNumber *itemId = [item objectForKey:@"id"];
                    Boolean newItem = true;
                    
                    //check to update
                    for(ListItem *listItem in listName.listItems) {
                        NSLog(@"list: %@ google: %@", listItem.listItemId, itemId);
                        if([listItem.listItemId isEqualToNumber:itemId]) {
                            NSLog(@"update item to list");
                            newItem = false; 
                            
                            [itemsToUpdate setValue:item forKey:[itemId stringValue]];
                        }
                    }
                    //check to add
                    if (newItem) {
                        NSLog(@"adding item to list");
                        
                        [itemsToAdd addObject:item];
                    }
                }
                
                //go through id's
                for(NSDictionary *item in itemsToUpdate) {
                    ListItem *listItem = [listName.listItems valueForKey:[item objectForKey:@"id"]];
                    
                    listItem.name = [item objectForKey:@"value"];
                    listItem.listItemId = [item objectForKey:@"id"];
                    listItem.done = [NSNumber numberWithBool:[[item objectForKey:@"done"] boolValue]];
                    listItem.modified = [item objectForKey:@"modified"];

                    [self.context save:&error];
                }
                
                for(NSDictionary *item in itemsToAdd) {
                    ListItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"ListItem" inManagedObjectContext:self.context];
                    newItem.name = [item objectForKey:@"value"];
                    newItem.listItemId = [item objectForKey:@"id"];
                    newItem.done = [NSNumber numberWithBool:[[item objectForKey:@"done"] boolValue]];
                    newItem.modified = [item objectForKey:@"modified"];
                    newItem.creation = [item objectForKey:@"modified"];
                    newItem.listName = listName;
                    
                    [listName addListItemsObject:newItem];
                    
                    [self.context save:&error];    

                }
                
                //check to delete
                for(ListItem *listItem in listName.listItems) {
                    Boolean deletItem = true;
                    for(NSDictionary *item in arrayOfItems) {
                        NSNumber *itemId = [item objectForKey:@"id"];
                        if([listItem.listItemId isEqualToNumber: itemId]) {
                            deletItem = false;
                        }
                    }
                    
                    if(deletItem) {
                        NSLog(@"delete item from list");
                        [self.context deleteObject:listItem];
                    }

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
		
		NSLog(@"%@, %@, %@", [list objectForKey:@"title"], [list objectForKey:@"id"], [list objectForKey:@"token"]);
		self.listName.name = [list objectForKey:@"title"];
		self.listName.listId = (NSNumber *)[list objectForKey:@"id"];
		self.listName.token = [list objectForKey:@"token"];
		self.listName.lastModified = [LightningUtil getUTCFormateDate:[NSDate date]];
        self.listName.shared = [NSNumber numberWithBool:[(NSString *)[list objectForKey:@"shared"] boolValue]];
        
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
        
        if ([self.listName.shared boolValue]) {
            [self.addListDelegate finishAddList:self.listName.token];
        }
		
		NSLog(@"created a list with response %@", [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] );
	}
    
    [self.context save:&error];
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishUpdateDevice:(NSData *)retrievedData error:(NSError *)error {
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with finishUpdateDevice: %i", status);
		
	} else {
        //TODO implement
		NSLog(@"finishUpdateDevice %@", [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding]);
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
		NSLog(@"finishedUpdateItem %@", [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding]);
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
		NSLog(@"created an item with response %@", [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding]);
		
		NSString *data = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];
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
		NSLog(@"pushed update to list response %@", [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding]);
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedReadList:(NSData *)retrievedData error:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with finishedReadList: %i", status);
		
	} else {
		NSLog(@"finishedReadList %@", [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding]);
        
        NSString *data = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];
		SBJSON *parser = [[SBJSON alloc] init];
		NSDictionary *object = [parser objectWithString:data error:nil];
        
        //Getting acutal List
		NSEntityDescription *entity   = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.context];
		NSPredicate * predicate;
		predicate = [NSPredicate predicateWithFormat:@"listId == %@", [object valueForKey:@"list"]];
		
		NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
		[fetch setEntity: entity];
		[fetch setPredicate: predicate];
		
		NSArray * results = [self.context executeFetchRequest:fetch error:nil];
		
		if([results count] > 0) {
			ListName *listName = [results objectAtIndex:0];
            listName.hasUnread = 0;
		}        
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishShareList:(NSData *)retrievedData error:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with finishWithShareList: %i", status);
		
	} else {
		NSLog(@"finishWithShareList %@", [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding]);
		
		[self getLists];
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishUpdateList:(NSData *)retrievedData error:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with finishUpdateList: %i", status);
		
	} else {
		NSLog(@"finishUpdateList %@", [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding]);
        
        if([self.listName.shared boolValue]) {
            NSString *data = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];
            SBJSON *parser = [[SBJSON alloc] init];
            NSDictionary *object = [parser objectWithString:data error:nil];
            
            self.listName.token = [object valueForKey:@"token"];

            [self.context save:&error];
            [self.addListDelegate finishAddList:self.listName.token];
        }
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishDeleteItem:(NSData *)retrievedData error:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with finishDeleteItem: %i", status);
		
	} else {
		NSLog(@"finishDeleteItem %@", [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding]);
        
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
