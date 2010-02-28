//
//  ListViewController.m
//  Lightning
//
//  Created by Cyril Gabathuler on 15.02.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import "ListViewController.h"


@implementation ListViewController

@synthesize listEntries;

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	NSLog(@"Foo %@", theTextField.text);
    [theTextField resignFirstResponder];
	self.tableView.scrollEnabled = YES;
	[listEntries.entries addObject:theTextField.text];
	[self.tableView reloadData];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	NSLog(@"Fii");
	self.tableView.scrollEnabled = YES;
	return YES;
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

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)editList {
	
}

- (void)viewWillAppear:(BOOL)animated {
    // Update the view with current data before it is displayed.
    [super viewWillAppear:animated];
    
    // Scroll the table view to the top before it appears
    [self.tableView reloadData];
    self.title = listEntries.title;
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
    return [listEntries.entries count]+1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	 
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
	NSLog(@"%i, %i2, %i3, %i4",i, i2, i3, i4);
	
	UITextField *label = [[[UITextField alloc] initWithFrame:cellFrame]autorelease];
	
	/*UIFont *font = [UIFont boldSystemFontOfSize:20.0];
	label.font = font;*/
	
	if(indexPath.row >= [listEntries.entries count]) {
		label.placeholder = @"New entry...";
	} else {
		label.text = [listEntries.entries objectAtIndex:indexPath.row];
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


- (void)dealloc {
	[listEntries release];
    [super dealloc];
}


@end

