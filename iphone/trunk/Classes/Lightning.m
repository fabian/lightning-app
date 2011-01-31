//
//  Lightning.m
//  Lightning
//
//  Created by Fabian on 3/16/10.
//  Copyright 2010 Liip AG. All rights reserved.
//

#import "Lightning.h";
#import "GTMHTTPFetcher.h";
#import "JSON.h";
#import "ListName.h";
#import "ListItem.h";
#import "LightningUtil.h";

@implementation Lightning

@synthesize url, device, deviceToken, lightningId, lightningSecret, context, delegate;

-(id)init {
	if(self = [super init]) {
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		self.lightningId = [userDefaults valueForKey:@"lightningId"];
		self.lightningSecret = [userDefaults valueForKey:@"lightningSecret"];
	}
	
	return self;
}

- (id)initWithURL:(NSURL *)initUrl andDeviceToken:(NSString*)initDeviceToken username:(NSString *)username{
    
	if(self = [super init]) {
		
		self.url = initUrl;
		
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		self.lightningId = [userDefaults valueForKey:@"lightningId"];
		self.lightningSecret = [userDefaults valueForKey:@"lightningSecret"];
		
		NSLog(@"lighntingId UserDefaults %@ and secret %@", self.lightningId, self.lightningSecret);
		
		if(self.lightningId == nil || self.lightningSecret == nil) {
			NSURL *callUrl = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingString:@"devices"]];
		
			NSLog(@"calling Url: %@", [callUrl description]);
		
			NSURLRequest *request = [NSURLRequest requestWithURL:callUrl];
			[callUrl release];
			
			GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
			[GTMHTTPFetcher setLoggingEnabled:YES];
			
		
			NSString * tokenAsString = [[[initDeviceToken description] 
									 stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] 
									stringByReplacingOccurrencesOfString:@" " withString:@""];
			NSString *postString = [NSString stringWithFormat:@"device_token=%@;name=%@;identifier=%@", [tokenAsString uppercaseString], username, [UIDevice currentDevice].uniqueIdentifier];
			[myFetcher setPostData:[postString dataUsingEncoding:NSUTF8StringEncoding]];
		
			[myFetcher beginFetchWithDelegate:self
						didFinishSelector:@selector(myFetcher:finishedWithData:error:)];
		} else {
			//[self createListWithTitle:@"poschte2"];
			//[self createItemWithValue:@"brot" andList:@"46002"];
			//[self getItemsFromList:@"46002" context:nil];
		}
    }
	
    return self;
}

-(void)createDeviceWithName:(NSString *)deviceName andDeviceToken:(NSString*) initDeviceToken{
	//name
	//device_token
	//identifier
}

-(void)addListWithTitle:(NSString *)listTitle context:(NSManagedObjectContext *)context{
	self.context = context;
	
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingFormat:@"lists?secret=%@", self.lightningSecret]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSURLRequest *request = [NSURLRequest requestWithURL:callUrl];
	[callUrl release];
	
	GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	NSString *postString = [NSString stringWithFormat:@"title=%@;owner=%@", listTitle, self.lightningId];
	[myFetcher setPostData:[postString dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSString *deviceHeader = [NSString stringWithFormat:@"%@devices/%@?secret=%@", self.url, self.lightningId, self.lightningSecret];
	[myFetcher setDeviceHeader:deviceHeader];

	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedWithAddingList:error:)];
}

-(void)addItemToList:(NSString *)listId item:(ListItem *)item context:(NSManagedObjectContext *)context{
	
	self.context = context;
	
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingFormat:@"items?secret=%@", self.lightningSecret]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSURLRequest *request = [NSURLRequest requestWithURL:callUrl];
	[callUrl release];
	
	GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
				
	NSString *postString = [NSString stringWithFormat:@"value=%@;list=%@", item.name, listId];
	[myFetcher setPostData:[postString dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSString *deviceHeader = [NSString stringWithFormat:@"%@devices/%@?secret=%@", self.url, self.lightningId, self.lightningSecret];
	[myFetcher setDeviceHeader:deviceHeader];
	
	[myFetcher setUserData:[item objectID]];
	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedWithCreatingItem:error:)];

}

-(void)pushUpdateForList:(NSString *)listId{
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingFormat:@"lists/%@/devices/%@/push", listId, self.lightningId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSURLRequest *request = [NSURLRequest requestWithURL:callUrl];
	[callUrl release];
	
	GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	NSString *postString = [NSString stringWithFormat:@""];
	[myFetcher setPostData:[postString dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSString *deviceHeader = [NSString stringWithFormat:@"%@devices/%@?secret=%@", self.url, self.lightningId, self.lightningSecret];
	[myFetcher setDeviceHeader:deviceHeader];
	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedWithPushToList:error:)];
}

-(void)getLists {
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingFormat:@"devices/%@/lists", self.lightningId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSURLRequest *request = [NSURLRequest requestWithURL:callUrl];
	[callUrl release];
	
	GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	NSString *deviceHeader = [NSString stringWithFormat:@"%@devices/%@?secret=%@", self.url, self.lightningId, self.lightningSecret];
	[myFetcher setDeviceHeader:deviceHeader];
	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedWithGetLists:error:)];
}

-(void)getListsWithContext:(NSManagedObjectContext *)context {
	self.context = context;
	
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingFormat:@"devices/%@/lists", self.lightningId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSURLRequest *request = [NSURLRequest requestWithURL:callUrl];
	[callUrl release];
	
	GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	NSString *deviceHeader = [NSString stringWithFormat:@"%@devices/%@?secret=%@", self.url, self.lightningId, self.lightningSecret];
	[myFetcher setDeviceHeader:deviceHeader];
	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedWithGetLists:error:)];
}

-(void)getItemsFromList:(NSString *)listId context:(NSManagedObjectContext *)context {
	self.context = context;
	
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingFormat:@"lists/%@", listId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSURLRequest *request = [NSURLRequest requestWithURL:callUrl];
	[callUrl release];
	
	GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	NSString *deviceHeader = [NSString stringWithFormat:@"%@devices/%@?secret=%@", self.url, self.lightningId, self.lightningSecret];
	[myFetcher setDeviceHeader:deviceHeader];
	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedWithGetItemsFromList:error:)];
	
}

-(void)shareList:(NSString *)listId token:(NSString *)token {
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingFormat:@"devices/%@/lists/%@", self.lightningId, listId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSURLRequest *request = [NSURLRequest requestWithURL:callUrl];
	[callUrl release];
	
	GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	NSString *putString = [NSString stringWithFormat:@"token=%@", token];
	[myFetcher setPutData:[putString dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSString *deviceHeader = [NSString stringWithFormat:@"%@devices/%@?secret=%@", self.url, self.lightningId, self.lightningSecret];
	[myFetcher setDeviceHeader:deviceHeader];
	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedWithShareList:error:)];
}

-(void)readList:(NSString *)listId {
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingFormat:@"lists/%@/devices/%@/read", listId, self.lightningId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSURLRequest *request = [NSURLRequest requestWithURL:callUrl];
	[callUrl release];
	
	GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	NSString *postString = [NSString stringWithFormat:@""];
	[myFetcher setPostData:[postString dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSString *deviceHeader = [NSString stringWithFormat:@"%@devices/%@?secret=%@", self.url, self.lightningId, self.lightningSecret];
	[myFetcher setDeviceHeader:deviceHeader];
	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedReadList:error:)];

}

-(void)updateItem:(ListItem *)listItem {
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingFormat:@"items/%@", listItem.listItemId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSURLRequest *request = [NSURLRequest requestWithURL:callUrl];
	[callUrl release];
	
	GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	NSString *putString = [NSString stringWithFormat:@"value=%@;done=%@;modified=%@", listItem.name, listItem.done, listItem.modified];
	NSLog(@"%@",putString);
	[myFetcher setPutData:[putString dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSString *deviceHeader = [NSString stringWithFormat:@"%@devices/%@?secret=%@", self.url, self.lightningId, self.lightningSecret];
	[myFetcher setDeviceHeader:deviceHeader];
	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedUpdateItem:error:)];
	
}

-(void)updateDevice:(NSString *)updatedDeviceToken andName:(NSString *)updatedName {
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingFormat:@"devices/%@", self.lightningId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSURLRequest *request = [NSURLRequest requestWithURL:callUrl];
	[callUrl release];
	
	GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	NSString * tokenAsString = [[[updatedDeviceToken description] 
								 stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] 
								stringByReplacingOccurrencesOfString:@" " withString:@""];
	
	NSString *putString = [NSString stringWithFormat:@"identifier=%@;name=%@;device_token=%@", [UIDevice currentDevice].uniqueIdentifier, updatedName, [tokenAsString uppercaseString]];
	NSLog(@"%@",putString);
	[myFetcher setPutData:[putString dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSString *deviceHeader = [NSString stringWithFormat:@"%@devices/%@?secret=%@", self.url, self.lightningId, self.lightningSecret];
	[myFetcher setDeviceHeader:deviceHeader];
	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishUpdateDevice:error:)];
	
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)retrievedData error:(NSError *)error {
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error creating device: %@", status);
	} else {
		//Testing methods
		NSString *data = [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease];
		SBJSON *parser = [[SBJSON alloc] init];
		NSDictionary *object = [parser objectWithString:data error:nil];
		self.lightningSecret = [object objectForKey:@"secret"];
		self.lightningId = [object objectForKey:@"id"];
		
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setValue:self.lightningId forKey:@"lightningId"];
		[userDefaults setValue:self.lightningSecret forKey:@"lightningSecret"];
		
		//[self createListWithTitle:@"poschte"];
		
		[parser release];
		
		NSLog(@"Response: %@", [object objectForKey:@"secret"]);
		// fetch succeeded
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedWithAddingList:(NSData *)retrievedData error:(NSError *)error {
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with creating list: %i", status);
	} else {
		//Testing methods
		NSString *data = [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease];
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
        if(![context save:&error]) {
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
		[self.delegate finishAddingList:[listName objectID]];
		
		NSLog(@"created a list with response %@", [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease]);
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedWithCreatingItem:(NSData *)retrievedData error:(NSError *)error {
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
		
		[parser autorelease];
		
		NSString *listId = [object objectForKey:@"list"];
		//Getting acutal List
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.context];
		NSPredicate * predicate;
		predicate = [NSPredicate predicateWithFormat:@"listId == %@", listId];
		
		NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
		[fetch setEntity: entity];
		[fetch setPredicate: predicate];
		
		NSArray * results = [context executeFetchRequest:fetch error:nil];
		[fetch release];
		
		if([results count] == 0) {
			NSLog(@"Something went wrong with CoreData");
		} else {
			ListName *listName = [results objectAtIndex:0];
			
			NSArray *items = [[listName listItems] allObjects];
			NSManagedObjectID *objectID	= nil;
			
			for (ListItem *item in items) {
				objectID = [fetcher userData];
				if ([objectID isEqual:[item objectID]]) {
				//if ([objectID isEqual:[item objectID]]) {
					
					item.name = [object objectForKey:@"value"];
					item.listItemId = [object objectForKey:@"id"];
					[context save:&error];
					break;
				}
			}
			
		}
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedWithPushToList:(NSData *)retrievedData error:(NSError *)error {
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

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedWithGetLists:(NSData *)retrievedData error:(NSError *)error {
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with getLists: %i", status);
		
		//calling the delegate eitherwise, so the coredata data can be displayed
		[self.delegate finishFetchingLists:retrievedData];
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
			
			NSArray * results = [context executeFetchRequest:fetch error:nil];
			[fetch release];
			
			for (NSManagedObject *managedObject in results) {
				[context deleteObject:managedObject];
			}
			
		} else {
			//Version1
			NSEntityDescription * entity   = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.context];
			
			NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
			[fetch setEntity: entity];
			
			NSArray * results = [context executeFetchRequest:fetch error:nil];
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
						
						[context save:&error];
						[self getItemsFromList:[list objectForKey:@"id"] context:self.context];
					} 
				}
				if(!isListExists) {
					//list is not existing
					if ([results count] > [arrayOfList count]) {
						//delete list
						NSLog(@"delete List");
						
						[context deleteObject:listName];
					} else {
						//add list
						NSLog(@"creating List");
						
						ListName *listName = nil;
						
						listName = [NSEntityDescription insertNewObjectForEntityForName:@"ListName" inManagedObjectContext:self.context];
						listName.name = [list objectForKey:@"title"];
						listName.listId = [list objectForKey:@"id"];
						listName.token = [list objectForKey:@"token"];
						listName.lastModified = [LightningUtil getUTCFormateDate:[NSDate date]];
						
						[context save:&error];
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
					
					NSArray * results = [context executeFetchRequest:fetch error:nil];
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
						 
						 [context save:&error];
					}
				}
			}
		}
		
		[self.delegate finishFetchingLists:retrievedData];
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedWithGetItemsFromList:(NSData *)retrievedData error:(NSError *)error {
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
		
		NSArray * results = [context executeFetchRequest:fetch error:nil];
		[fetch release];
		
		if([results count] == 0) {
			NSLog(@"Something went wrong with CoreData");
		} else {
			ListName *listName = [results objectAtIndex:0];
			
			NSArray *arrayOfItems = [object objectForKey:@"items"];
			
			if ([arrayOfItems count] == 0) {
				//TODO doe this work?
				listName.listItems = nil;
				[context save:&error];
				
			} else {
				NSMutableArray *listItems = [[listName listItems] mutableCopy];
				NSMutableDictionary *listItemsWithKeysCoreData = [NSMutableDictionary dictionaryWithCapacity:[listItems count]];
				
				for (ListItem *listItem in listItems) {
					[listItemsWithKeysCoreData setValue:listItem forKey:listItem.listItemId];
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
							[context deleteObject:listItem];
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
					
					[context save:&error];
				}
				
				[listItems release];
			}
			
			/*
			for (NSDictionary *item in arrayOfItems) {
				ListItem *listItem = [NSEntityDescription insertNewObjectForEntityForName:@"ListItem" inManagedObjectContext:self.context];
				listItem.name = [item objectForKey:@"value"];
				listItem.listItemId = [item objectForKey:@"id"];
				
				[listName addListItemsObject:listItem];
			}
			
			 */
		}
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedWithShareList:(NSData *)retrievedData error:(NSError *)error {
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with finishWithShareList: %i", status);
		
	} else {
		NSLog(@"finishWithShareList %@", [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease]);
		
		[self getLists];
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedReadList:(NSData *)retrievedData error:(NSError *)error {
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with finishedReadList: %i", status);
		
	} else {
		NSLog(@"finishedReadList %@", [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease]);
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

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishUpdateDevice:(NSData *)retrievedData error:(NSError *)error {
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with finishUpdateDevice: %i", status);
		
	} else {
		NSLog(@"finishUpdateDevice %@", [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease]);
	}
}

- (id)initWithURL:(NSURL *)url andDevice:(NSString *)device {
    
	//Not in use right now!!
	
	/*if(self = [super init]) {
		
		self.url = url;
		self.device = device;
    }*/
	
    return self;
}

- (void)dealloc {
    [url release];
	[device release];
    [super dealloc];
}


- (void) reloadData:(NSDictionary *)data {
	NSLog(@"delegate called IHAA");
	//always getting url in response, so its "easy" to get the service name
}

@end
