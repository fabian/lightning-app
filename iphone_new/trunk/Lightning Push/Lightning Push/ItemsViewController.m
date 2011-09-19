//
//  ItemsViewController.m
//  Lightning Push
//
//  Created by Cyril Gabathuler on 06.09.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ItemsViewController.h"
#import "EditListViewController.h"

@interface ItemsViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation ItemsViewController

@synthesize listName = _listName;
@synthesize lightningAPI = _lightningAPI;
@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize timer = _timer;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (id)initWithStyle:(UITableViewStyle)style;
{
    self = [super initWithStyle:style];
    if (self) {
        self.lightningAPI = [LightningAPI sharedManager];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    // Set up the edit and add buttons.
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.backgroundColor = [UIColor clearColor];
	
	[self setWantsFullScreenLayout:YES];
	
	self.tableView.contentInset = UIEdgeInsetsMake(-420, 0, -420, 0);
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resignActive)
												 name:UIApplicationWillResignActiveNotification 
											   object:NULL];
	
    UIImageView *top = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top.jpg"]];
	self.tableView.tableHeaderView = top;
    
	UIImageView *bottom = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bottom.jpg"]];
	self.tableView.tableFooterView = bottom;
    
    self.title = self.listName.name;
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editList)];
	self.navigationItem.rightBarButtonItem = button;
    
    [self.lightningAPI readList:self.listName.listId];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    if([self.listName.shared boolValue]) {
        [self.lightningAPI pushUpdateForList:self.listName.listId];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    [NSFetchedResultsController deleteCacheWithName:@"Items"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    //For the 'new entry...' cell
    return [sectionInfo numberOfObjects]+1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"middleWithLine.jpg"]];
		
		cell.backgroundView = imageView;
		
		CGRect cellFrame = cell.bounds;
		cellFrame.origin.x += 40;
		cellFrame.origin.y +=5;	
		cellFrame.size.width -= 68;
		cellFrame.size.height -= 5;
		
		UITextField *label = [[UITextField alloc] initWithFrame:cellFrame];
		label.tag = 123;
		
		/*UIFont *font = [UIFont boldSystemFontOfSize:20.0];
		 label.font = font;*/
		if(indexPath.row >= [[self.fetchedResultsController fetchedObjects] count]) {
			label.placeholder = @"New entry...";
		} else {
			ListItem *listItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
			
			label.text = listItem.name;
			
			if([listItem.done boolValue]) {
				CGFloat width =  [label.text sizeWithFont:label.font].width;
				Line *line = [[Line alloc] initWithFrame:CGRectMake(label.frame.origin.x, label.frame.origin.y+20, width, 3)];
				line.backgroundColor = [UIColor clearColor];
				line.tag = 124;
				[cell.contentView addSubview:line];
			}
		}
		
		label.delegate = self;
		
		label.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		label.adjustsFontSizeToFitWidth = YES;
		
		label.autocorrectionType = UITextAutocorrectionTypeNo;
		label.autocapitalizationType = UITextAutocapitalizationTypeSentences;
		label.borderStyle = UITextBorderStyleNone;
		label.backgroundColor = [UIColor clearColor];
		label.returnKeyType = UIReturnKeyDone;
		
		//cell.textLabel.text = [listEntries.entries objectAtIndex:indexPath.row];
		[cell.contentView addSubview:label];
		
		
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

}

 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {  
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	
	UIView *existingLine = [cell viewWithTag:124];
	
	
	if (existingLine == nil) {
		UITextField *label = (UITextField *)[cell.contentView viewWithTag:123];
		
		if([label.text length] > 0) {
			CGFloat width =  [label.text sizeWithFont:label.font].width;
			Line *line = [[Line alloc] initWithFrame:CGRectMake(label.frame.origin.x, label.frame.origin.y+20, width, 3)];
			line.backgroundColor = [UIColor clearColor];
			line.tag = 124;
			[cell.contentView addSubview:line];
            
			ListItem *listItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
            
			listItem.modified = [LightningUtil getUTCFormateDate:[NSDate date]];
			listItem.done = [NSNumber numberWithBool:TRUE];
            
			NSError *error;
            [self.listName willChangeValueForKey:@"listItems"];
			[self.managedObjectContext save:&error];
            
            [self.lightningAPI updateItem:listItem];
		}
	} else {
		[existingLine removeFromSuperview];
		ListItem *listItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
		
		listItem.modified = [LightningUtil getUTCFormateDate:[NSDate date]];
		listItem.done = [NSNumber numberWithBool:FALSE];
		
		NSError *error;
        [self.listName willChangeValueForKey:@"listItems"];
		[self.managedObjectContext save:&error];
		
		[self.lightningAPI updateItem:listItem];
		
	}
	
	
	return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //do something
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (__fetchedResultsController != nil) {
        return __fetchedResultsController;
    }
    
    // Set up the fetched results controller.
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ListItem" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"listName == %@", self.listName];
    [fetchRequest setPredicate:predicate];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creation" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Items"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    /*
	     Replace this implementation with code to handle the error appropriately.
         
	     abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	     */
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return __fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView reloadData];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
 // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
 {
 // In the simplest, most efficient, case, reload the table view.
 [self.tableView reloadData];
 }
 */

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
  	if(indexPath.row >= [[self.fetchedResultsController fetchedObjects] count]) {
		UITextField *label = (UITextField*)[cell.contentView viewWithTag:123];
        label.placeholder = @"New entry...";
        label.text = nil;
    } else {
        UITextField *label = (UITextField*)[cell.contentView viewWithTag:123];
        ListItem *listItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
        label.text = [listItem name];
        
        if([listItem.done boolValue]) {
            CGFloat width =  [label.text sizeWithFont:label.font].width;
            Line *line = [[Line alloc] initWithFrame:CGRectMake(label.frame.origin.x, label.frame.origin.y+20, width, 3)];
            line.backgroundColor = [UIColor clearColor];
            line.tag = 124;
            [cell.contentView addSubview:line];			}
    }
}

# pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    //user hasn't done anything
    
    if ([theTextField.text length] == 0) {
		[theTextField resignFirstResponder];
		return YES;
	}
    
    UITableViewCell *cell = (UITableViewCell *)[[theTextField superview] superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    if (indexPath.row >= [[self.fetchedResultsController fetchedObjects] count]) {
        NSLog(@"new entry..");
        
        ListItem *listItem = [NSEntityDescription insertNewObjectForEntityForName:@"ListItem" inManagedObjectContext:self.managedObjectContext];
		listItem.name = theTextField.text;
		listItem.creation = [LightningUtil getUTCFormateDate:[NSDate date]];
		listItem.modified = [LightningUtil getUTCFormateDate:[NSDate date]];
		listItem.listName = self.listName;
        listItem.done = FALSE;
		
		NSError *error;
		[self.managedObjectContext save:&error];
		
		[self.lightningAPI addItemToList:self.listName.listId item:listItem];
    } else {
        NSLog(@"modifying one");
        
        ListItem *listItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
		listItem.modified = [LightningUtil getUTCFormateDate:[NSDate date]];
		listItem.name = theTextField.text;
		
        NSError *error;
		[self.managedObjectContext save:&error];
		
        [self.lightningAPI updateItem:listItem];
    }
    
    //Start the timer
    if([[self.listName shared] boolValue]) {
        NSDate *d = [NSDate dateWithTimeIntervalSinceNow: 15.0];
        self.timer = [[NSTimer alloc] initWithFireDate:d interval:0 target:self selector:@selector(pushAfterTimer) userInfo:nil repeats:NO];
        NSRunLoop *runner = [NSRunLoop currentRunLoop];
        [runner addTimer:self.timer forMode: NSDefaultRunLoopMode];
    }
    
    [theTextField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	//Kill timer
	if ([self.timer isValid]) {
		[self.timer invalidate];
		NSLog(@"killed the timer");
	}
	
	return YES;
}

#pragma mark - edit list

- (void)editList {
	
	EditListViewController *editListViewController = [[EditListViewController alloc] initWithStyle:UITableViewStyleGrouped];
    editListViewController.managedObjectContext = self.managedObjectContext;
    editListViewController.listName = self.listName;
    
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:editListViewController];
	navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	
    [self presentModalViewController:navigationController animated:YES];
}

#pragma mark - push methods

-(void)pushAfterTimer {
    NSLog(@"pushing after timer");	
    [self.lightningAPI pushUpdateForList:[self.listName listId]];
}

- (void)resignActive {
	if ([[self.listName shared] boolValue]) {
        NSLog(@"pushing because user closes the app");
        [self.lightningAPI pushUpdateForList:[self.listName listId]];
    }
}

@end
