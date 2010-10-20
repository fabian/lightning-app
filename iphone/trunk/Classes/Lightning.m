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
#import "ListName.h"
#import "ListItem.h"

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

- (id)initWithURL:(NSURL *)initUrl andDeviceToken:(NSString*)initDeviceToken{
    
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
			GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
			[GTMHTTPFetcher setLoggingEnabled:YES];
		
			NSString * tokenAsString = [[[initDeviceToken description] 
									 stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] 
									stringByReplacingOccurrencesOfString:@" " withString:@""];
			NSString *postString = [NSString stringWithFormat:@"device_token=%@;name=%@;identifier=%@", [tokenAsString uppercaseString], @"testiphone", [UIDevice currentDevice].uniqueIdentifier];
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

-(void)createListWithTitle:(NSString *)listTitle{
	
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingFormat:@"lists?secret=%@", self.lightningSecret]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSURLRequest *request = [NSURLRequest requestWithURL:callUrl];
	GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	NSString *postString = [NSString stringWithFormat:@"title=%@;owner=%@", listTitle, self.lightningId];
	[myFetcher setPostData:[postString dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSString *deviceHeader = [NSString stringWithFormat:@"%@devices/%@?secret=%@", self.url, self.lightningId, self.lightningSecret];
	[myFetcher setDeviceHeader:deviceHeader];

	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedWithCreatingList:error:)];
}

-(void)addItemToList:(NSString *)listId item:(ListItem *)item context:(NSManagedObjectContext *)context{
	
	self.context = context;
	
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingFormat:@"items?secret=%@", self.lightningSecret]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSURLRequest *request = [NSURLRequest requestWithURL:callUrl];

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
	//exclude?
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingFormat:@"lists/%@/push?secret=%@", listId, self.lightningSecret]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSURLRequest *request = [NSURLRequest requestWithURL:callUrl];
	GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	NSString *postString = [NSString stringWithFormat:@""];
	[myFetcher setPostData:[postString dataUsingEncoding:NSUTF8StringEncoding]];
	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedWithPushToList:error:)];
}

-(void)getLists {
	NSURL *callUrl = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingFormat:@"devices/%@/lists", self.lightningId]];
	
	NSLog(@"calling Url: %@", [callUrl description]);
	
	NSURLRequest *request = [NSURLRequest requestWithURL:callUrl];
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
	GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[GTMHTTPFetcher setLoggingEnabled:YES];
	
	NSString *deviceHeader = [NSString stringWithFormat:@"%@devices/%@?secret=%@", self.url, self.lightningId, self.lightningSecret];
	[myFetcher setDeviceHeader:deviceHeader];
	
	[myFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(myFetcher:finishedWithGetItemsFromList:error:)];
	
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)retrievedData error:(NSError *)error {
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error creating device");
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
		
		NSLog(@"Response: %@", [object objectForKey:@"secret"]);
		// fetch succeeded
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedWithCreatingList:(NSData *)retrievedData error:(NSError *)error {
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with creating list");
	} else {
		//Testing methods
		NSString *data = [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease];
		SBJSON *parser = [[SBJSON alloc] init];
		NSDictionary *object = [parser objectWithString:data error:nil];
		NSString *listId = [object objectForKey:@"id"];
		
		//[self createItemWithValue:@"red bull" andList:listId];
		
		NSLog(@"created a list with response %@", [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding]);
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedWithCreatingItem:(NSData *)retrievedData error:(NSError *)error {
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with creating item on list");
	} else {
		NSLog(@"created an item with response %@", [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding]);
		
		NSString *data = [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease];
		SBJSON *parser = [[SBJSON alloc] init];
		NSDictionary *object = [parser objectWithString:data error:nil];
		
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
		NSLog(@"error with push to list");
	} else {
		NSLog(@"pushed update to list response %@", [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding]);
	}
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher finishedWithGetLists:(NSData *)retrievedData error:(NSError *)error {
	if (error != nil) {
		// failed; either an NSURLConnection error occurred, or the server returned
		// a status value of at least 300
		//
		// the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
		int status = [error code];
		NSLog(@"error with getLists");
		
		//calling the delegate eitherwise, so the coredata data can be displayed
		[self.delegate finishFetchingLists:retrievedData];
	} else {
		NSLog(@"getLists response %@", [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding]);
		
		NSString *data = [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease];
		SBJSON *parser = [[SBJSON alloc] init];
		NSDictionary *object = [parser objectWithString:data error:nil];
		NSArray *arrayOfList = [object objectForKey:@"lists"];
		
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
			
			for (NSDictionary *list in arrayOfList) {
				NSEntityDescription    * entity   = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.context];
				NSPredicate * predicate;
				predicate = [NSPredicate predicateWithFormat:@"listId != %@", [list objectForKey:@"id"]];
			
				NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
				[fetch setEntity: entity];
				[fetch setPredicate: predicate];
			
				NSArray * results = [context executeFetchRequest:fetch error:nil];
				[fetch release];
			
				for (NSManagedObject *managedObject in results) {
					[context deleteObject:managedObject];
				}
			}
		}

		
		for (NSDictionary *list in arrayOfList) {
			//checking if existing
			NSEntityDescription    * entity   = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.context];
			NSPredicate * predicate;
			predicate = [NSPredicate predicateWithFormat:@"listId == %@", [list objectForKey:@"id"]];
			
			NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
			[fetch setEntity: entity];
			[fetch setPredicate: predicate];
			
			NSArray * results = [context executeFetchRequest:fetch error:nil];
			[fetch release];
			
			
			
			if([results count] == 0) {
				NSLog(@"creating List");
				
				ListName *listName = nil;
				
				listName = [NSEntityDescription insertNewObjectForEntityForName:@"ListName" inManagedObjectContext:self.context];
				listName.name = [list objectForKey:@"title"];
				listName.listId = [list objectForKey:@"id"];
				listName.unreadCount = [list objectForKey:@"unread"];
				
				[context save:&error];
				
				
				
				
			} else {
				//update listelement
				NSLog(@"update list");
				
				 ListName *listName = [results objectAtIndex:0];
				 
				 listName.name = [list objectForKey:@"title"];
				 listName.listId = [list objectForKey:@"id"];
				 listName.unreadCount = [list objectForKey:@"unread"];
				 
				 [context save:&error];
				 [self getItemsFromList:[list objectForKey:@"id"] context:self.context];
				 //[listName release];
				 
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
		NSLog(@"error with getItemsFromList");
		
	} else {
		NSLog(@"getItemsFromList response %@", [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding]);
		
		NSString *data = [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease];
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
		
		NSArray * results = [context executeFetchRequest:fetch error:nil];
		[fetch release];
		
		if([results count] == 0) {
			NSLog(@"Something went wrong with CoreData");
		} else {
			ListName *listName = [results objectAtIndex:0];
			
			NSArray *arrayOfItems = [object objectForKey:@"items"];
			
			for (NSDictionary *item in arrayOfItems) {
				ListItem *listItem = [NSEntityDescription insertNewObjectForEntityForName:@"ListItem" inManagedObjectContext:self.context];
				listItem.name = [item objectForKey:@"value"];
				listItem.listItemId = [item objectForKey:@"id"];
				
				[listName addListItemsObject:listItem];
			}
			[context save:&error];
		}
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

- (void)addListWithTitle:(NSString *)title {
	
	NSArray *keys = [NSArray arrayWithObjects:@"title", @"owner", nil];
	NSArray *values = [NSArray arrayWithObjects:title, @"52", nil];
	NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
	
	NSURL *url = [[NSURL alloc] initWithString:[[self.url absoluteString] stringByAppendingString:@"lists"]];
	
	//ApiRequest *request = [[ApiRequest alloc] initWithURL:url andDevice:device];
	//[request post:parameters];
}


- (void) reloadData:(NSDictionary *)data {
	NSLog(@"delegate called IHAA");
	//always getting url in response, so its "easy" to get the service name
}

@end
