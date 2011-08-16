//
//  ShareListViewController.m
//  Lightning
//
//  Created by Cyril Gabathuler on 24.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import "AddListViewController.h"
#import "ListViewController.h"

@implementation AddListViewController

@synthesize delegate, checkmark, listNameTextField, context, sharedList;
@synthesize lightningAPI = _lightningAPI;


 - (id)initWithStyle:(UITableViewStyle)style {
 // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
     if (self = [super initWithStyle:style]) {
         self.lightningAPI = [LightningAPI sharedManager];
     }
     
     return self;
 }


 - (void)viewDidLoad {
	 [super viewDidLoad];
	 
	 UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAddList)];
	 self.navigationItem.rightBarButtonItem = doneButton;
	 [self.navigationItem.rightBarButtonItem setEnabled:NO];

	 [doneButton release];
	 
	 UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAddList)];
	 self.navigationItem.leftBarButtonItem = cancelButton;
	 
	 [cancelButton release];

	 
	 checkmark = 0;
	 
 // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
 // self.navigationItem.rightBarButtonItem = self.editButtonItem;
 }

-(void)cancelAddList{
	[self dismissModalViewControllerAnimated:YES];
}
 
- (void)doneAddList {
	NSLog(@"doneAddList");
	[self.navigationItem.leftBarButtonItem setEnabled:NO];
	
	[self.navigationItem.rightBarButtonItem setEnabled:NO];
	[self.listNameTextField becomeFirstResponder];
	[self.listNameTextField resignFirstResponder];
	
	
	if (checkmark == 1) {
		[self showLoadingView];
		
        self.lightningAPI.addListDelegate = self;
        [self.lightningAPI addList:self.listNameTextField.text];
	} else {
		[self.delegate finishAddPrivateList:listNameTextField.text];
	}
}

// Dismisses the email composition interface when users tap Cancel or Send.
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
	[self.delegate performSelector: @selector(finishAddSharedList:) withObject:[self.sharedList token] afterDelay: 0.5f];
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
/*
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	if(section == 0) {
		return tableView.tableHeaderView;
	} else {
		UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(10, 10, 100, 80)] autorelease];
		
		UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(18, 0, 200, 20)];
		label.text = @"Share list with";
		[label setBackgroundColor:tableView.backgroundColor];
		[view addSubview:label];
		
		return view;
	}
	
}*/

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if(section == 0)
		return 30;
	else
		return 30;
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
        
        // Set up the cell...
        if(indexPath.section == 0) {
            listNameTextField = [[UITextField alloc] initWithFrame:CGRectMake(16, 10, cell.frame.size.width-16, cell.frame.size.height-10)];
            listNameTextField.placeholder = @"Set name of list";
            
            listNameTextField.delegate = self;
            [listNameTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingDidEnd];
            
            [cell addSubview: listNameTextField];
            //cell.textLabel.text = @"Set name of list";
        } else {
            if(0 == indexPath.row){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                cell.textLabel.text = @"Private";
                cell.detailTextLabel.text = @"ja isches";
                cell.imageView.image = [UIImage imageNamed:@"Icon-Private.png"];
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.text	= @"Share with others";
                cell.detailTextLabel.text = @"denke schon";
                cell.imageView.image = [UIImage imageNamed:@"Icon-Shared.png"];
            }
            
        }
    }
    
    if(indexPath.section == 1) {
        if(0 == indexPath.row){
            if (checkmark == 0) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        } else {
            if (checkmark == 1) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
            
    }   
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
		
	    
    if (checkmark == 0) {
        checkmark = 1;
    } else {
        checkmark = 0;
    }
    
    [self.tableView reloadData];
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

-(void)showLoadingView
{
	CGRect transparentViewFrame = CGRectMake(0.0, 0.0,320.0,480.0);
	UIView *transparentView = [[UIView alloc] initWithFrame:transparentViewFrame];
	transparentView.tag = 13;
	transparentView.backgroundColor = [UIColor blackColor];
	transparentView.alpha = 0.9;
	
	UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	spinner.center = transparentView.center;
	[spinner startAnimating];
	
	UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 160, 320, 30)];
	messageLabel.textAlignment = UITextAlignmentCenter;
	messageLabel.text = @"Loading...";
	messageLabel.font = [UIFont systemFontOfSize:20.0];
	messageLabel.textColor = [UIColor whiteColor];
	messageLabel.backgroundColor = [UIColor clearColor];
	
	[transparentView addSubview:spinner];
	[transparentView addSubview:messageLabel];
	
	[self.view addSubview:transparentView];
	
	[messageLabel release];
	[spinner release];
	[transparentView release];
}

-(void)dismissLoadingView {
	[[self.view viewWithTag:13] removeFromSuperview];
}

- (void)finishAddList:(NSString *)token {
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.context];
	
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"token == %@", token];
    
	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
	[fetch setEntity: entity];
    [fetch setPredicate:predicate];
	
	NSArray * results = [context executeFetchRequest:fetch error:nil];
    
    if ([results count] == 1) {
        
        ListName *listName = [results objectAtIndex:0];
        NSError *error;
        listName.shared = [NSNumber numberWithBool:TRUE];
        [context save:&error];
        
        self.sharedList = listName;
        
        MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
        mailComposer.mailComposeDelegate = self;
        
        NSString *subject = [NSString stringWithFormat:@"Lightning invite for list: %@", listName.name];
        [mailComposer setSubject:subject];
        
        // Fill out the email body text
        NSString *emailBody = [NSString stringWithFormat:@"This is an invite with for the list: <a href=\"lightning://list/%@?token=%@\">%@</a>", listName.listId, listName.token, listName.name];
        NSLog(@"link: <a href=\"lightning://list/%@?token=%@\">%@</a>", listName.listId, listName.token, listName.name);
        [mailComposer setMessageBody:emailBody isHTML:YES];
        
        [self presentModalViewController:mailComposer animated:YES];
        [mailComposer release];

    }
}

- (void)textFieldDidChange:(id)sender { 
	
	UITextField *changedTextField = (UITextField *)sender;
	
	if ([changedTextField.text length] > 0) {
		[self.navigationItem.rightBarButtonItem setEnabled:YES];
	} else {
		[self.navigationItem.rightBarButtonItem setEnabled:NO];
	}

	
}

- (void)dealloc {
    [super dealloc];
	[listNameTextField release];
}


@end


