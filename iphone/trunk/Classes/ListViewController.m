//
//  ListViewController.m
//  Lightning
//
//  Created by Cyril Gabathuler on 15.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import "ListViewController.h"
#import "ListItem.h"


@implementation ListViewController

@synthesize listEntries, listItems, context, listName, doneTextField, showMail;

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	NSLog(@"Foo %@", theTextField.text);
    [theTextField becomeFirstResponder];
	self.tableView.scrollEnabled = YES;
	[listEntries.entries addObject:theTextField.text];
	
	ListItem *listItem = [NSEntityDescription insertNewObjectForEntityForName:@"ListItem" inManagedObjectContext:context];
	listItem.name = theTextField.text;
	listItem.creation = [self getUTCFormateDate:[NSDate date]];

	[listName addListItemsObject:listItem];
	
	NSError *error;
	[context save:&error];
	
	self.listItems = [[listName listItems] allObjects];
	
	NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"creation" ascending:YES];
	NSMutableArray *sorted = [[NSMutableArray alloc] initWithArray:listItems];
	[sorted sortUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
	self.listItems = sorted;
	
	[sorted release];
	
	[self.tableView reloadData];
	
	//Adding Item to List
	Lightning *lightning = [[Lightning alloc]init];
	lightning.delegate = self;
	lightning.url = [NSURL URLWithString:@"https://lightning-app.appspot.com/api/"];
	
	//CoreData
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"ListName" inManagedObjectContext:self.context];
	NSPredicate * predicate;
	predicate = [NSPredicate predicateWithFormat:@"listId == %@", listName.listId];
	
	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
	[fetch setEntity: entity];
	[fetch setPredicate: predicate];
	
	NSArray * results = [context executeFetchRequest:fetch error:nil];
	[fetch release];
	
	if([results count] == 0) {
		NSLog(@"Something went wrong with CoreData");
	} else {
		ListName *listNameCoreData = [results objectAtIndex:0];
		
		NSArray *items = [[listNameCoreData listItems] allObjects];
		
		for (ListItem *item in items) {
			if (item.listItemId == nil || [item.listItemId isEqualToNumber:[NSNumber numberWithInt:0]]) {
				//NSManagedObjectID *objectID = [item objectID];
				[lightning addItemToList:(NSString*)listNameCoreData.listId item:item context:self.context];
			}
		}
	}
	
	
	NSLog(@"foo second");
    return YES;
}

-(NSString *)getUTCFormateDate:(NSDate *)localDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:localDate];
	
    return dateString;
}

/*- (void)textFieldDidEndEditing:(UITextField *)textField {
	if(doneTextField != nil) {
		[textField becomeFirstResponder];
		NSLog(@"its not nil");
	}
}*/

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	NSLog(@"Fii");
	self.tableView.scrollEnabled = YES;
	//check how to give a selector a parameter
	//just wright doneAdding: the method the has to look like doneAdding:(id)sender
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAdding)];
	self.navigationItem.rightBarButtonItem = button;
	doneTextField = textField;
	[button release];
	
	return YES;
}

- (void)doneAdding {
	NSLog(@"done adding");
    [doneTextField resignFirstResponder];
	doneTextField = nil;
	
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editList)];
	self.navigationItem.rightBarButtonItem = button;
	[button release];	
	
}

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
		
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		self.tableView.backgroundColor = [UIColor redColor];
		
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
	
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editList)];
	self.navigationItem.rightBarButtonItem = button;
	[button release];
	
	//getting items
	//Lightning *lightning = [[Lightning alloc]init];
	//lightning.delegate = self;
	//lightning.url = [NSURL URLWithString:@"https://lightning-app.appspot.com/api/"];
	//create corresponding service call
	//[lightning getListsWithContext:self.context];
	
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
			ListViewController *listViewController = [[ListViewController alloc] initWithStyle:UITableViewStylePlain];
			[listViewController registerForKeyboardNotifications];
			
			[self.navigationController pushViewController:listViewController animated:YES];
			[listViewController release];
			break;
		case MFMailComposeResultFailed:
			NSLog(@"Result: failed");
			break;
		default:
			NSLog(@"Result: not sent");
			break;
	}
	
	
	[self dismissModalViewControllerAnimated:YES];
}

- (void)editList {
	
}

- (void)viewWillAppear:(BOOL)animated {
    // Update the view with current data before it is displayed.
    [super viewWillAppear:animated];
    
    // Scroll the table view to the top before it appears
    [self.tableView reloadData];
    self.title = listName.name;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
	if (self.showMail) {
		self.showMail = FALSE;
		
		MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
		mailComposer.mailComposeDelegate = self;
		
		NSString *subject = [NSString stringWithFormat:@"Group invite for groupname: %@", @"mhm"];
		[mailComposer setSubject:subject];
		
		// Fill out the email body text
		NSString *emailBody = @"This is an group invite bla bla";
		[mailComposer setMessageBody:emailBody isHTML:NO];
		
		[self presentModalViewController:mailComposer animated:YES];
		[mailComposer release];	
	}
	
}

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
    NSLog(@"listItems count: %i", [listItems count]);
	return [listItems count]+1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"middleWithLine.jpg"]];
		
		cell.backgroundView = imageView;
		
		[imageView release];
		
		CGRect cellFrame = cell.bounds;
		cellFrame.origin.x += 40;
		int i = cellFrame.origin.x;
		cellFrame.origin.y +=5;	
		int i2 = cellFrame.origin.y;
		cellFrame.size.width -= 68;
		int i3 = cellFrame.size.width;
		cellFrame.size.height -= 5;
		int i4 = cellFrame.size.height;
		
		UITextField *label = [[[UITextField alloc] initWithFrame:cellFrame]autorelease];
		label.tag = 123;
		
		/*UIFont *font = [UIFont boldSystemFontOfSize:20.0];
		 label.font = font;*/
		if(indexPath.row >= [listItems count]) {
			label.placeholder = @"New entry...";
		} else {
			ListItem *listItem = [listItems objectAtIndex:indexPath.row];
			label.text = [listItem name];
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
		
    } else {
		if(indexPath.row >= [listItems count]) {
			UITextField *label = (UITextField*)[cell.contentView viewWithTag:123];
			label.placeholder = @"New entry...";
			label.text = nil;
		} else {
			UITextField *label = (UITextField*)[cell.contentView viewWithTag:123];
			ListItem *listItem = [listItems objectAtIndex:indexPath.row];
			label.text = [listItem name];
		}

	}


	
	return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"DELETESTYLE");
	
	/*UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	NSArray *subviews = [cell.contentView subviews];
	UITextField *textfield = (UITextField *)[subviews objectAtIndex:0];

	NSString *htmlString = htmlString=@"<div style=\"font-family:Helvetica, Arial, sans-serif; font-size: 14pt; text-decoration: line-through; font-weight:bold;\">";
	htmlString = [htmlString stringByAppendingString:textfield.text];
	htmlString = [htmlString stringByAppendingString:@"</div>"];
	
	UIWebView *webView = [[UIWebView alloc] initWithFrame:[cell frame]];
	[webView loadHTMLString:htmlString baseURL:nil];
	[textfield removeFromSuperview];
	[cell.contentView addSubview:webView];
	
	[cell release];*/
	
	return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
	NSLog(@"select row?");
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}




// Override to support editing the table view.
/*
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

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWasShown:)
												 name:UIKeyboardDidShowNotification object:nil];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWasHidden:)
												 name:UIKeyboardDidHideNotification object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    if (keyboardShown)
        return;
	
    NSDictionary* info = [aNotification userInfo];
	
    // Get the size of the keyboard.
    NSValue* aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
    CGSize keyboardSize = [aValue CGRectValue].size;
	
    // Resize the scroll view (which is the root view of the window)
    CGRect viewFrame = [self.view frame];
    viewFrame.size.height -= keyboardSize.height;
    self.view.frame = viewFrame;
	
    // Scroll the active text field into view.
    CGRect tableCellRect = [activeCell frame];
	tableCellRect.size.height += 320;
	
    [(UITableView*)self.view scrollRectToVisible:tableCellRect animated:YES];
    viewFrame.size.height += keyboardSize.height;
    self.view.frame = viewFrame;
	
    keyboardShown = YES;
}


// Called when the UIKeyboardDidHideNotification is sent
- (void)keyboardWasHidden:(NSNotification*)aNotification
{
    keyboardShown = NO;
}


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    activeCell = (UITableViewCell*)textField.superview.superview;
	NSLog(@"start");
}

- (void)dealloc {
	[listEntries release];
    [super dealloc];
}


@end

