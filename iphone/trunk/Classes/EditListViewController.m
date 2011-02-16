//
//  EditListViewController.m
//  Lightning
//
//  Created by Cyril Gabathuler on 16.02.11.
//  Copyright 2011 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import "EditListViewController.h"


@implementation EditListViewController

@synthesize context, list;

#pragma mark -
#pragma mark Initialization


- (id)initWithStyle:(UITableViewStyle)style context:(NSManagedObjectContext *)context_ list:(ListName *)list_ {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:style];
    if (self) {
		self.context = context_;
		self.list = list_;
    }
    return self;
}



#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Edit List";
	
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAddList)];
	self.navigationItem.rightBarButtonItem = doneButton;
	[self.navigationItem.rightBarButtonItem setEnabled:NO];
	
	[doneButton release];
	
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAddList)];
	self.navigationItem.leftBarButtonItem = cancelButton;
	
	[cancelButton release];
	
	//self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top.jpg"]];
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
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
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

-(void)cancelAddList{
	[self dismissModalViewControllerAnimated:YES];
}

-(void)doneAddList{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)deleteMarkedEntries:(id) sender {
	NSLog(@"delete marked entries");
}

- (void)deleteList:(id) sender {
	NSLog(@"delete list");
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    
	if([list.shared boolValue]){
		return 2;
	}	
	else {
		return 1;
	}

}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 2;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
	if(indexPath.section == 0) {
		if(0 == indexPath.row){
			if (![list.shared boolValue]) {
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			}
			cell.textLabel.text = @"Private";
			cell.detailTextLabel.text = @"ja isches";
			cell.imageView.image = [UIImage imageNamed:@"Icon-Private.png"];
		} else {
			if ([list.shared boolValue]) {
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			}
			cell.textLabel.text	= @"Share with others";
			cell.detailTextLabel.text = @"denke schon";
			cell.imageView.image = [UIImage imageNamed:@"Icon-Shared.png"];
		}
	} else {
		cell.textLabel.text = @"Nibbler jn.";
		cell.detailTextLabel.text = @"detail text?";
	}
	
    
    return cell;
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
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
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

//own view for title
/*
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	// create the parent view that will hold header Label
	UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(10.0, 0.0, 300.0, 44.0)];
	
	// create the button object
	UILabel * headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	headerLabel.backgroundColor = [UIColor clearColor];
	headerLabel.opaque = NO;
	headerLabel.textColor = [UIColor blackColor];
	headerLabel.highlightedTextColor = [UIColor whiteColor];
	headerLabel.font = [UIFont boldSystemFontOfSize:20];
	headerLabel.frame = CGRectMake(20.0, 0.0, 300.0, 44.0);
	
	// If you want to align the header text as centered
	// headerLabel.frame = CGRectMake(150.0, 0.0, 300.0, 44.0);
	
	headerLabel.text = @"test"; // i.e. array element
	[customView addSubview:headerLabel];
	
	return customView;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 44.0;
}*/

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if(section == 0)
		return @"Your list is";
	else
		return @"Shared with";
	
}

// specify the height of your footer section
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    //differ between your sections or if you
    //have only on section return a static value
	
	int sectionHeight = 0;
	
	if([list.shared boolValue]) {
		sectionHeight = 1;
	}
	
    if (section == sectionHeight) {
		return 100;
	}
}

// custom view for footer. will be adjusted to default or specified footer height
// Notice: this will work only for one section within the table view
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	
    if(footerView == nil) {
        //allocate the view if it doesn't exist yet
        footerView  = [[UIView alloc] init];
		
        //we would like to show a gloosy red button, so get the image first
        UIImage *image = [[UIImage imageNamed:@"button_red.png"]
						  stretchableImageWithLeftCapWidth:8 topCapHeight:8];
		
        //create the button
        UIButton *entriesDeletebutton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [entriesDeletebutton setBackgroundImage:image forState:UIControlStateNormal];	
		
        //the button should be as big as a table view cell
        [entriesDeletebutton setFrame:CGRectMake(10, 13, 300, 44)];
		
        //set title, font size and font color
        [entriesDeletebutton setTitle:@"Delete marked entries" forState:UIControlStateNormal];
        [entriesDeletebutton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
        [entriesDeletebutton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		
        //set action of the button
        [entriesDeletebutton addTarget:self action:@selector(deleteMarkedEntries:)
		 forControlEvents:UIControlEventTouchUpInside];
		
		
		//Create second button
		
		//we would like to show a gloosy red button, so get the image first
        /*UIImage *image = [[UIImage imageNamed:@"button_red.png"]
						  stretchableImageWithLeftCapWidth:8 topCapHeight:8];*/
		
        //create the button
        UIButton *deleteListButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [deleteListButton setBackgroundImage:image forState:UIControlStateNormal];	
		
        //the button should be as big as a table view cell
        [deleteListButton setFrame:CGRectMake(10, 60, 300, 44)];
		
        //set title, font size and font color
        [deleteListButton setTitle:@"Delete List" forState:UIControlStateNormal];
        [deleteListButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
        [deleteListButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		
        //set action of the button
        [deleteListButton addTarget:self action:@selector(deleteList:)
		 forControlEvents:UIControlEventTouchUpInside];
		
		//add the button to the view
        [footerView addSubview:entriesDeletebutton];
        [footerView addSubview:deleteListButton];
		
		
    }
	
    //return the view for the footer
    return footerView;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    /*
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
    */
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

