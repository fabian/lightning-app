//
//  EditListViewController.m
//  Lightning
//
//  Created by Cyril Gabathuler on 16.02.11.
//  Copyright 2011 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import "EditListViewController.h"

@interface EditListViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation EditListViewController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize listName = _listName;
@synthesize footerMailView = _footerMailView;
@synthesize footerDeleteView = _footerDeleteView;
@synthesize lightningAPI = _lightningAPI;

#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
        self.lightningAPI = [LightningAPI sharedManager];
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
	
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAddList)];
	self.navigationItem.leftBarButtonItem = cancelButton;
    
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

- (void)mailSharedList:(id) sender {
	NSLog(@"mail shared list");
    
    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
    mailComposer.mailComposeDelegate = self;
    
    NSString *subject = [NSString stringWithFormat:@"Lightning invite for list: %@", self.listName.name];
    [mailComposer setSubject:subject];
    
    // Fill out the email body text
    NSString *emailBody = [NSString stringWithFormat:@"This is an invite with for the list: <a href=\"lightning://list/%@?token=%@\">%@</a>", self.listName.listId, self.listName.token, self.listName.name];
    NSLog(@"link: <a href=\"lightning://list/%@?token=%@\">%@</a>", self.listName.listId, self.listName.token, self.listName.name);
    [mailComposer setMessageBody:emailBody isHTML:YES];
    
    [self presentModalViewController:mailComposer animated:YES];
    
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    
	if([self.listName.shared boolValue]){
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
        // Set up the cell...
        if(indexPath.section == 0) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            if(0 == indexPath.row){
                if (![self.listName.shared boolValue]) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                cell.textLabel.text = @"Private";
                cell.detailTextLabel.text = @"ja isches";
                cell.imageView.image = [UIImage imageNamed:@"Icon-Private.png"];
            } else {
                if ([self.listName.shared boolValue]) {
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
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0) {
        if(0 == indexPath.row){
            if (![self.listName.shared boolValue]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        } else {
            if ([self.listName.shared boolValue]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
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
	
	if([self.listName.shared boolValue]) {
		if (section == 0) {
			return 58;
		}
	} 
	
	return 116;
}

// custom view for footer. will be adjusted to default or specified footer height
// Notice: this will work only for one section within the table view
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	NSLog(@"section: %i", section);
	
    //if((section == 0 && ![list.shared boolValue]) || (section == 1 && [list.shared boolValue])) {
	if((section == 0 && ![self.listName.shared boolValue]) || (section == 1 && [self.listName.shared boolValue])) {
		if (self.footerDeleteView == nil) {
			//allocate the view if it doesn't exist yet
			self.footerDeleteView  = [[UIView alloc] init];
			
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
			[entriesDeletebutton addTarget:self action:@selector(deleteEntries:)
						  forControlEvents:UIControlEventTouchUpInside];
			
            //add the button to the view
			[self.footerDeleteView addSubview:entriesDeletebutton];
		}
		//return the view for the footer
		return self.footerDeleteView;
    } else {
		if (self.footerMailView == nil) {
			//allocate the view if it doesn't exist yet
			self.footerMailView  = [[UIView alloc] init];
			
			//we would like to show a gloosy red button, so get the image first
			UIImage *image = [[UIImage imageNamed:@"button_red.png"]
							  stretchableImageWithLeftCapWidth:8 topCapHeight:8];
			
			//create the button
			UIButton *mailButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
			[mailButton setBackgroundImage:image forState:UIControlStateNormal];	
			
			//the button should be as big as a table view cell
			[mailButton setFrame:CGRectMake(10, 13, 300, 44)];
			
			//set title, font size and font color
			[mailButton setTitle:@"Mail shared list" forState:UIControlStateNormal];
			[mailButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
			[mailButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
			
			//set action of the button
			[mailButton addTarget:self action:@selector(mailSharedList:)
						  forControlEvents:UIControlEventTouchUpInside];
			
			[self.footerMailView addSubview:mailButton];
		}
		return self.footerMailView;
	}

	
    //return nil;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"what is selected section: %i row: %i", indexPath.section, indexPath.row);
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	switch (indexPath.section) {
		case 0:
			NSLog(@"test");
			//new
            if (indexPath.row == 0 && [self.listName.shared boolValue]) {
                self.listName.shared = [NSNumber numberWithBool:FALSE];

                NSError *error;
                [self.managedObjectContext save:&error];
                
                [self.lightningAPI updateList:self.listName];
                
            } else if(indexPath.row == 1 && ![self.listName.shared boolValue]) {
                self.listName.shared = [NSNumber numberWithBool:TRUE];
                
                NSError *error;
                [self.managedObjectContext save:&error];
                
                self.lightningAPI.addListDelegate = self;
                [self.lightningAPI updateList:self.listName];
                
            }
            
            [tableView reloadData];
			
			break;
		case 1:
			//
			break;

		default:
			break;
	}
}

#pragma mark - uiactionview

- (void)finishAddList:(NSString *)token {
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:@"Share Email" delegate:self cancelButtonTitle:@"send email later" destructiveButtonTitle:nil otherButtonTitles:@"Send email now", nil];
    
    [actionSheet showInView:self.tableView];

}

- (void) deleteEntries:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:@"Delete entries" delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"delete all", @"delete marked", nil];
    
    [actionSheet showInView:self.tableView];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSLog(@"buttonindex %@", [NSNumber numberWithInteger:buttonIndex]);
	
    if([actionSheet.title isEqualToString:@"Share Email"]) {
        NSLog(@"email");
        if(buttonIndex == 0) {
            NSLog(@"send email now");
            
            
            MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
            mailComposer.mailComposeDelegate = self;
            
            NSString *subject = [NSString stringWithFormat:@"Lightning invite for list: %@", self.listName.name];
            [mailComposer setSubject:subject];
            
            // Fill out the email body text
            NSString *emailBody = [NSString stringWithFormat:@"This is an invite with for the list: <a href=\"lightning://list/%@?token=%@\">%@</a>", self.listName.listId, self.listName.token, self.listName.name];
            NSLog(@"link: <a href=\"lightning://list/%@?token=%@\">%@</a>", self.listName.listId, self.listName.token, self.listName.name);
            [mailComposer setMessageBody:emailBody isHTML:YES];
            
            [self presentModalViewController:mailComposer animated:YES];

        }
    } else {
        
        if(buttonIndex == 0) {
            NSLog(@"delete all");
            for (ListItem *listItem in [self.listName.listItems allObjects]) {
                [self.lightningAPI deleteItem:[listItem.listItemId stringValue]];

                [self.managedObjectContext deleteObject:listItem];
            }
            NSError *error;
            [self.managedObjectContext save:&error];
            
        } else if(buttonIndex == 1) {
            NSLog(@"delete marked");
            
            for (ListItem *listItem in [self.listName.listItems allObjects]) {
                if (listItem.done) {
                    [self.lightningAPI deleteItem:[listItem.listItemId stringValue]];
                    
                    [self.managedObjectContext deleteObject:listItem];
                }
                
            }
            NSError *error;
            [self.managedObjectContext save:&error];

        }
                        
    }
    
    
}

#pragma mark - mail

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	NSLog(@"error mail: %@", error);
	// Notifies users about errors associated with the interface
	switch (result)
	{
		case MFMailComposeResultCancelled:
			NSLog(@"Result: canceled");
			break;
		case MFMailComposeResultSaved:
			NSLog(@"Result: saved");
			break;
		case MFMailComposeResultSent:
			NSLog(@"Result: sent");
			break;
		case MFMailComposeResultFailed:
			NSLog(@"Result: failed");
			break;
		default:
			NSLog(@"Result: not sent");
			break;
	}
	
	[self.navigationController dismissModalViewControllerAnimated:YES];
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



@end

