//
//  AddListViewController.m
//  Lightning
//
//  Created by Cyril Gabathuler on 08.03.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import "AddListViewController.h"
#import "ShareListViewController.h"

@implementation AddListViewController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
 // Custom initialization
 }
 return self;
 }
 */


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	NSLog(@"AddListViewController");
	ShareListViewController *shareListViewController = [[ShareListViewController alloc] init];
	
	UITableView *shareListView = [[UITableView alloc]initWithFrame:CGRectMake(100, 30, 100, 200) style:UITableViewStylePlain];
	//dont know yet how to add the delegate and datasource
	
	//shareListView.delegate = shareListViewController;
	//shareListView.dataSource = shareListViewController;
	
	
	[self.navigationController.view addSubview:shareListView];
	
	[shareListViewController release];
}



 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
/* - (void)viewDidLoad {
 [super viewDidLoad];

 }*/
 

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */
/*
- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}
*/
- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
