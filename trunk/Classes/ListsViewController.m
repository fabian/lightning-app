//
//  ListsViewController.m
//  Lightning
//
//  Created by Cyril Gabathuler on 15.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import "ListsViewController.h"
#import "ListViewController.h"
#import "AddListViewController.h"

@implementation ListsViewController

@synthesize lists;


- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		self.tableView.backgroundColor = [UIColor clearColor];
		
		UIImageView *top = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top.jpg"]];
		self.tableView.tableHeaderView = top;
		[top release];
		
		UIImageView *bottom = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bottom.jpg"]];
		self.tableView.tableFooterView = bottom;
		[bottom release];
		
		self.tableView.contentInset = UIEdgeInsetsMake(-420, 0, -420, 0);
    }
    return self;
}



- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self setLists:[[Lists alloc] init]];
	
	self.tableView.allowsSelectionDuringEditing = YES;
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addList)];
	self.navigationItem.rightBarButtonItem = button;
	[button release];
	
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (IBAction)addList {
	NSLog(@"addList");
	AddListViewController *addListViewController = [[AddListViewController alloc] initWithStyle:UITableViewStylePlain];
	
	[self.navigationController pushViewController:addListViewController animated:YES];
	[addListViewController release];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	self.title = lists.title;
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSLog(@"list count: %i", [lists countOfList]);
    return [lists countOfList];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		
	}
	
	UIImageView *accessory = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"accessory.png"]];
	accessory.frame =CGRectMake(270, 14, accessory.frame.size.width, accessory.frame.size.height);
	
	[cell addSubview:accessory];
	
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"middleWithLine.jpg"]];
	
	cell.backgroundView = imageView;
	
	[imageView release];
	
	
	CGRect cellFrame = cell.bounds;
	cellFrame.origin.x += 40;
	int i = cellFrame.origin.x;
	cellFrame.origin.y +=2;	
	int i2 = cellFrame.origin.y;
	cellFrame.size.width -= 68;
	int i3 = cellFrame.size.width;
	cellFrame.size.height -= 5;
	int i4 = cellFrame.size.height;
	NSLog(@"%i, %i2, %i3, %i4",i, i2, i3, i4);
	
	UILabel *label = [[UILabel alloc] initWithFrame:cellFrame];
	
    // Set up the cell...
	NSString *listEntry = [lists titleOfListAtIndex:indexPath.row];
	label.text	= listEntry;
	label.backgroundColor = [UIColor clearColor];
	UIFont *font = [UIFont boldSystemFontOfSize:20.0];
	label.font = font;
	[cell addSubview:label];
	
	UILabel *roundedLabel = [[UILabel alloc]initWithFrame:CGRectMake(230, 10, 30, 20)];	
	roundedLabel.textColor = [UIColor whiteColor];
	roundedLabel.text=@"1";
	roundedLabel.textAlignment = UITextAlignmentCenter;
	roundedLabel.backgroundColor = [UIColor grayColor];
	CALayer *layer = [roundedLabel layer];
	layer.borderColor = [[UIColor grayColor] CGColor];
    layer.borderWidth = 1.0f;
    layer.cornerRadius = 10.0f;
	
	[cell addSubview:roundedLabel];
	
	[listEntry release];
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	ListViewController *listViewController = [[ListViewController alloc] initWithStyle:UITableViewStylePlain];
	listViewController.listEntries = [lists listEntriesAtIndex:indexPath.row];
	[listViewController registerForKeyboardNotifications];
	
	[self.navigationController pushViewController:listViewController animated:YES];
	[listViewController release];
	
	
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


- (void)dealloc {
	[lists release];
    [super dealloc];
}


@end

