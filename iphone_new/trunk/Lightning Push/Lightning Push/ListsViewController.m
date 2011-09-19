//
//  MasterViewController.m
//  Lightning Push
//
//  Created by Cyril Gabathuler on 06.09.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ListsViewController.h"
#import "ItemsViewController.h"

#import <QuartzCore/QuartzCore.h>

@interface ListsViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation ListsViewController

@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize itemsViewController = _itemsViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Master", @"Master");
    }
    return self;
}
							
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    // Set up the edit and add buttons.
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.backgroundColor = [UIColor clearColor];
	
	[self setWantsFullScreenLayout:YES];
	
	self.tableView.contentInset = UIEdgeInsetsMake(-420, 0, -420, 0);
	
    UIImageView *top = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top.jpg"]];
	self.tableView.tableHeaderView = top;
	
	UIImageView *bottom = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bottom.jpg"]];
	self.tableView.tableFooterView = bottom;

    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addList)];
    self.navigationItem.rightBarButtonItem = addButton;
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
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
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
    return [sectionInfo numberOfObjects];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        UIImageView *accessory = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"accessory.png"]];
		accessory.frame =CGRectMake(270, 16, accessory.frame.size.width, accessory.frame.size.height);
		
		[cell addSubview:accessory];
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"middleWithLine.jpg"]];
		
		cell.backgroundView = imageView;
        
        CGRect cellFrame = cell.bounds;
		cellFrame.origin.x += 40;
		cellFrame.origin.y +=4;	
		cellFrame.size.width -= 68;
		cellFrame.size.height -= 5;
		
		UILabel *label = [[UILabel alloc] initWithFrame:cellFrame];
		
		label.backgroundColor = [UIColor clearColor];
		UIFont *font = [UIFont systemFontOfSize:20.0];
		label.font = font;
		label.tag = 10;
		
        [cell.contentView addSubview:label];
        
        UILabel *roundedLabel = [[UILabel alloc]initWithFrame:CGRectMake(230, 14, 30, 20)];	
        roundedLabel.textColor = [UIColor grayColor];
        roundedLabel.textAlignment = UITextAlignmentCenter;
        roundedLabel.backgroundColor = [UIColor clearColor];
        CALayer *layer = [roundedLabel layer];
        layer.cornerRadius = 10.0f;
        
        roundedLabel.tag = 124;
        [cell.contentView addSubview:roundedLabel];
    }

    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object for the given index path
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ListName *listName = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    
    ItemsViewController *itemsViewController = [[ItemsViewController alloc] initWithStyle:UITableViewStylePlain];
    
    itemsViewController.managedObjectContext = self.managedObjectContext;
    itemsViewController.listName = listName;
    [self.navigationController pushViewController:itemsViewController animated:YES];
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
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastModified" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Lists"];
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

- (void)finishAddSharedList:(NSString *)token {
	NSLog(@"finishAddSharedList");
    
    [self dismissModalViewControllerAnimated:YES];
    [self.navigationController pushViewController:self.itemsViewController animated:YES];
    self.itemsViewController = nil;
    
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    ListName *listName = anObject;
    
    ItemsViewController *itemsViewController = [[ItemsViewController alloc] initWithStyle:UITableViewStylePlain];
    itemsViewController.managedObjectContext = self.managedObjectContext;
    itemsViewController.listName = listName;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            itemsViewController.managedObjectContext = self.managedObjectContext;
            itemsViewController.listName = listName;    
            
            self.itemsViewController = itemsViewController;
            
           // if ([listName.shared boolValue]) {
                //[self.navigationController pushViewController:itemsViewController animated:YES];
            //}
            
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
    ListName *listName = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    UILabel *textLabel = (UILabel *)[cell.contentView viewWithTag:10];
    [textLabel setText:listName.name];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"done != 1"];
    NSArray *filteredArray = [[listName.listItems allObjects] filteredArrayUsingPredicate:predicate];
    int unreadItems = 0;
    if ([filteredArray count] > 0) {
        unreadItems = [filteredArray count];
    }
    
    UILabel *roundedLabel = (UILabel*)[cell.contentView viewWithTag:124];
    //[listName.unreadCount intValue] > 0
    
        if (roundedLabel != nil) {
            roundedLabel.text = [[NSString alloc ]initWithFormat:@"%i", unreadItems];
            if ([listName.unreadCount boolValue]) {
                roundedLabel.textColor = [UIColor whiteColor];
                roundedLabel.backgroundColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness: 0.0 alpha:0.45];
            } else {
                roundedLabel.textColor = [UIColor grayColor];
                roundedLabel.backgroundColor = [UIColor clearColor];
            }
        } else {
            roundedLabel = [[UILabel alloc]initWithFrame:CGRectMake(230, 14, 30, 20)];	
            roundedLabel.textColor = [UIColor whiteColor];
            roundedLabel.textAlignment = UITextAlignmentCenter;
            
            if ([listName.unreadCount boolValue]) {
                 roundedLabel.textColor = [UIColor whiteColor];
                roundedLabel.backgroundColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness: 0.0 alpha:0.45];
            } else {
                roundedLabel.textColor = [UIColor grayColor];
                roundedLabel.backgroundColor = [UIColor clearColor];
            }
            
                        
            roundedLabel.text = [[NSString alloc ]initWithFormat:@"%i", unreadItems];
            roundedLabel.tag = 124;
            
            [cell.contentView addSubview:roundedLabel];
        }
        
    
    
}

- (void)insertNewObject
{
    // Create a new instance of the entity managed by the fetched results controller.
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    // If appropriate, configure the new managed object.
    // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
    [newManagedObject setValue:@"test" forKey:@"name"];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark - Add List

- (void)addList {
	NSLog(@"addList");
	
	AddListViewController *addListViewController = [[AddListViewController alloc] initWithStyle:UITableViewStyleGrouped];
	addListViewController.delegate = self;
    addListViewController.context = [self.fetchedResultsController managedObjectContext];
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:addListViewController];
	navigationController.navigationBar.barStyle = UIBarStyleBlack;
	navigationController.navigationBar.translucent = YES;
    [self presentModalViewController:navigationController animated:YES];
}

- (void)finishAddPrivateList:(NSString *)listName{
	NSLog(@"finishAddList");
	[self dismissModalViewControllerAnimated:YES];
    
    //[self insertNewObject];
}

@end
