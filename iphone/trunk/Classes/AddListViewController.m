//
//  ShareListViewController.m
//  Lightning
//
//  Created by Cyril Gabathuler on 24.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import "AddListViewController.h"
#import "AddNewGroup.h"
#import "ListViewController.h"

@implementation AddListViewController

@synthesize delegate, indexPathCell1, indexPathCell2, checkmark, listName;

/*
 - (id)initWithStyle:(UITableViewStyle)style {
 // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 if (self = [super initWithStyle:style]) {
 }
 return self;
 }
 */


 - (void)viewDidLoad {
	 [super viewDidLoad];
	 
	 UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAddList)];
	 self.navigationItem.rightBarButtonItem = button;
	 [button release];
	 
	 checkmark = 0;
	 
 // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
 // self.navigationItem.rightBarButtonItem = self.editButtonItem;
 }
 
- (void)doneAddList {
	NSLog(@"doneAddList");
	[self.delegate finishAddList:checkmark:listName.text];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	self.title = @"Add List";
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
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if(section == 0)
		return @"Adding a new list";
	else
		return @"Share list with";

}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	if(section == 0) {
		return tableView.tableHeaderView;
	} else {
		UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(10, 10, 100, 80)] autorelease];
		
		UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[button	addTarget:self action:@selector(addGroup) forControlEvents:UIControlEventTouchUpInside];
		button.frame = CGRectMake(10, 30, 300, 40);
		[button setTitle:@"Add new group" forState:UIControlStateNormal];
		[view addSubview:button];
		
		UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(18, 0, 200, 20)];
		label.text = @"Share list with";
		[label setBackgroundColor:tableView.backgroundColor];
		[view addSubview:label];
		
		return view;
	}
	
}

- (void)addGroup {
	NSLog(@"addGroup");
	
	//AddNewGroup *newGroup = [[AddNewGroup alloc]initWithFrame:[self.view frame]];
	AddNewGroup *newGroup = [[AddNewGroup alloc]init];
	newGroup.delegate = self;
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:newGroup];
	navigationController.navigationBar.barStyle = UIBarStyleBlack;
	navigationController.navigationBar.translucent = YES;
	
	//newGroup.view.frame = self.view.frame;
	newGroup.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	
	[self presentModalViewController:navigationController animated:YES];
	//[self.navigationController pushViewController:newGroup animated:YES];
	
	[navigationController release];
	[newGroup release];
}

- (void)finishAddGroup {
	[self dismissModalViewControllerAnimated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if(section == 0)
		return 30;
	else
		return 80;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0)
		return 1;
	
	return 2;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    // Set up the cell...
	if(indexPath.section == 0) {
		listName = [[UITextField alloc] initWithFrame:CGRectMake(16, 10, cell.frame.size.width-16, cell.frame.size.height-10)];
		listName.placeholder = @"Set name of list";
		listName.delegate = self;
		[cell addSubview: listName];
		//cell.textLabel.text = @"Set name of list";
	} else {
		
		
		if(0 == indexPath.row){
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
			cell.textLabel.text = @"Private";
			cell.detailTextLabel.text = @"ja isches";
			indexPathCell1 = indexPath;
			cell.imageView.image = [UIImage imageNamed:@"private.png"];
		} else {
			cell.textLabel.text	= @"Share with others";
			cell.detailTextLabel.text = @"denke schon";
			indexPathCell2 = indexPath;
			cell.imageView.image = [UIImage imageNamed:@"sharing.png"];
		}

	}
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
		
	UITableViewCell *cell1 = [self.tableView cellForRowAtIndexPath:indexPathCell1];
	UITableViewCell *cell2 = [self.tableView cellForRowAtIndexPath:indexPathCell2];
	
	if(checkmark != indexPath.row) {
		if (checkmark == 0) {
			cell1.accessoryType = UITableViewCellAccessoryNone;
			cell2.accessoryType = UITableViewCellAccessoryCheckmark;
			checkmark = 1;
			
		} else {
			cell1.accessoryType = UITableViewCellAccessoryCheckmark;
			cell2.accessoryType = UITableViewCellAccessoryNone;
			checkmark = 0;
		}
	}
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

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	return YES;
}

- (void)dealloc {
    [super dealloc];
	[listName release];
}


@end


