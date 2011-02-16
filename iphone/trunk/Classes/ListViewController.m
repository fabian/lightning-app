//
//  ListViewController.m
//  Lightning
//
//  Created by Cyril Gabathuler on 15.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import "ListViewController.h"
#import "ListItem.h"
#import	"LightningUtil.h"
#import	"Line.h";
#import	"EditListViewController.h";

@implementation ListViewController

@synthesize listEntries, listItems, context, listName, doneTextField, timer;

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	NSLog(@"Foo %@", theTextField.text);
    [theTextField becomeFirstResponder];
	self.tableView.scrollEnabled = YES;
	
	if ([theTextField.text length] == 0) {
		[theTextField resignFirstResponder];
		return YES;
	}
	
	[listEntries.entries addObject:theTextField.text];
	
	//Adding Item to List
	Lightning *lightning = [[[Lightning alloc]init] autorelease];
	lightning.delegate = self;
	lightning.url = [NSURL URLWithString:@"https://lightning-app.appspot.com/api/"];
	
	if (activeCell.editing) {
		
		ListItem *listItem = [self.listItems objectAtIndex:activeCell.indexPath.row];
		listItem.modified = [LightningUtil getUTCFormateDate:[NSDate date]];
		listItem.name = theTextField.text;
		NSError *error;
		[context save:&error];
		
		[lightning updateItem:listItem];
		[self.tableView reloadData];
	} else {
		
		ListItem *listItem = [NSEntityDescription insertNewObjectForEntityForName:@"ListItem" inManagedObjectContext:context];
		listItem.name = theTextField.text;
		listItem.creation = [LightningUtil getUTCFormateDate:[NSDate date]];
		listItem.modified = [LightningUtil getUTCFormateDate:[NSDate date]];
		
		[listName addListItemsObject:listItem];
		
		NSError *error;
		[context save:&error];
		
		[lightning addItemToList:listName.listId item:listItem context:self.context];

		
		NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"creation" ascending:YES];
		NSMutableArray *sorted = [[NSMutableArray alloc] initWithArray:[[listName listItems] allObjects]];
		[sorted sortUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
		self.listItems = sorted;
		
		[descriptor release];
		[sorted release];
		
		[self.tableView reloadData];
		
	}

	//Start the timer
	NSDate *d = [NSDate dateWithTimeIntervalSinceNow: 15.0];
	timer = [[NSTimer alloc] initWithFireDate:d interval:0 target:self selector:@selector(pushAfterTimer) userInfo:nil repeats:NO];
	NSRunLoop *runner = [NSRunLoop currentRunLoop];
	[runner addTimer:timer forMode: NSDefaultRunLoopMode];
	
	NSLog(@"foo second");
    return YES;
}

-(void)pushAfterTimer {
	NSLog(@"pushing after timer");
	Lightning *lightning = [[[Lightning alloc]init] autorelease];
	lightning.delegate = self;
	lightning.url = [NSURL URLWithString:@"https://lightning-app.appspot.com/api/"];	
	[lightning pushUpdateForList:[self.listName listId]];
}

/*- (void)textFieldDidEndEditing:(UITextField *)textField {
	if(doneTextField != nil) {
		[textField becomeFirstResponder];
		NSLog(@"its not nil");
	}
}*/

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	NSLog(@"Fii");
	
	activeCell = (ItemTableViewCell*)textField.superview.superview;
	
	if ([textField.text length] > 0) {
		activeCell.editing = true;
	} else {
		activeCell.editing = false;
	}

	
	//Kill timer
	if ([timer isValid]) {
		[timer invalidate];
		NSLog(@"killed the timer");
	}
	
	self.tableView.scrollEnabled = YES;
	
	doneTextField = textField;
	
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

- (id)initWithStyle:(UITableViewStyle)style listName:(ListName *)listNameInit{
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
		
		self.listName = listNameInit;
    }
    return self;
}



- (void)viewDidLoad {
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
	[top release];
	
	UIImageView *bottom = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bottom.jpg"]];
	self.tableView.tableFooterView = bottom;
	[bottom release];
	
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editList)];
	self.navigationItem.rightBarButtonItem = button;
	[button release];
	
	//getting items
	//Lightning *lightning = [[Lightning alloc]init];
	//lightning.delegate = self;
	//lightning.url = [NSURL URLWithString:@"http://localhost:8080p.appspot.com/api/"];
	//create corresponding service call
	//[lightning getListsWithContext:self.context];
	
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	Lightning *lightning = [[[Lightning alloc] init] autorelease];
	lightning.delegate = self;
	lightning.url = [NSURL URLWithString:@"https://lightning-app.appspot.com/api/"];	
	[lightning readList:[self.listName listId]];
}

- (void)editList {
	
	EditListViewController *editListViewController = [[EditListViewController alloc] initWithStyle:UITableViewStyleGrouped context:self.context list:self.listName];

	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:editListViewController];
	navigationController.navigationBar.barStyle = UIBarStyleBlack;
	navigationController.navigationBar.translucent = YES;
	navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	
    [self presentModalViewController:navigationController animated:YES];
    
    [navigationController release];
	[editListViewController release];
	
}

- (void)viewWillAppear:(BOOL)animated {
    // Update the view with current data before it is displayed.
    [super viewWillAppear:animated];
    
    // Scroll the table view to the top before it appears
    [self.tableView reloadData];
    self.title = listName.name;
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/


- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	NSLog(@"pushing because the user is going back to the main view");
	Lightning *lightning = [[[Lightning alloc]init] autorelease];
	lightning.delegate = self;
	lightning.url = [NSURL URLWithString:@"https://lightning-app.appspot.com/api/"];	
	[lightning pushUpdateForList:[self.listName listId]];
}

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
    
    ItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    if (cell == nil) {
        cell = [[[ItemTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.indexPath = indexPath;
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"middleWithLine.jpg"]];
		
		cell.backgroundView = imageView;
		
		[imageView release];
		
		CGRect cellFrame = cell.bounds;
		cellFrame.origin.x += 40;
		cellFrame.origin.y +=5;	
		cellFrame.size.width -= 68;
		cellFrame.size.height -= 5;
		
		UITextField *label = [[[UITextField alloc] initWithFrame:cellFrame]autorelease];
		label.tag = 123;
		
		/*UIFont *font = [UIFont boldSystemFontOfSize:20.0];
		 label.font = font;*/
		if(indexPath.row >= [listItems count]) {
			label.placeholder = @"New entry...";
		} else {
			ListItem *listItem = [listItems objectAtIndex:indexPath.row];
			
			label.text = [listItem name];
			
			if([listItem.done boolValue]) {
				CGFloat width =  [label.text sizeWithFont:label.font].width;
				Line *line = [[Line alloc] initWithFrame:CGRectMake(label.frame.origin.x, label.frame.origin.y+20, width, 3)];
				line.backgroundColor = [UIColor clearColor];
				line.tag = 124;
				[cell.contentView addSubview:line];

				[line release];
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
		
		
    } else {
		if(indexPath.row >= [listItems count]) {
			UITextField *label = (UITextField*)[cell.contentView viewWithTag:123];
			label.placeholder = @"New entry...";
			label.text = nil;
		} else {
			UITextField *label = (UITextField*)[cell.contentView viewWithTag:123];
			ListItem *listItem = [listItems objectAtIndex:indexPath.row];
			label.text = [listItem name];
			
			if([listItem.done boolValue]) {
				CGFloat width =  [label.text sizeWithFont:label.font].width;
				Line *line = [[Line alloc] initWithFrame:CGRectMake(label.frame.origin.x, label.frame.origin.y+20, width, 3)];
				line.backgroundColor = [UIColor clearColor];
				line.tag = 124;
				[cell.contentView addSubview:line];
				
				[line release];
			}
		}

	}

	
	
	return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"DELETESTYLE");
	
	Lightning *lightning = [[[Lightning alloc]init] autorelease];
	lightning.delegate = self;
	lightning.url = [NSURL URLWithString:@"https://lightning-app.appspot.com/api/"];	
	
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
		
			ListItem *listItem = [listItems objectAtIndex:indexPath.row];
		
			listItem.modified = [LightningUtil getUTCFormateDate:[NSDate date]];
			listItem.done = [NSNumber numberWithBool:TRUE];
		
			NSError *error;
			[context save:&error];
		
			[lightning updateItem:listItem];
			[line release];
		}
	} else {
		[existingLine removeFromSuperview];
		ListItem *listItem = [listItems objectAtIndex:indexPath.row];
		
		listItem.modified = [LightningUtil getUTCFormateDate:[NSDate date]];
		listItem.done = [NSNumber numberWithBool:FALSE];
		
		NSError *error;
		[context save:&error];
		
		[lightning updateItem:listItem];
		
	}
	
	
	return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
	NSLog(@"didSelectRowAtIndexPath");
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
		NSLog(@"canEditRowAtIndexPath");
    return YES;
}




// Override to support editing the table view.

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"commitEditingStyle");
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}



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
	NSLog(@"start");
}

- (void)resignActive {
	NSLog(@"pushing because user closes the app");
	Lightning *lightning = [[[Lightning alloc]init] autorelease];
	lightning.delegate = self;
	lightning.url = [NSURL URLWithString:@"https://lightning-app.appspot.com/api/"];	
	[lightning pushUpdateForList:[self.listName listId]];
	
}

- (void)dealloc {
	[listEntries release];
	[timer release];
    [super dealloc];
}


@end

