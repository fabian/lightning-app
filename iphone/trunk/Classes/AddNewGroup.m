//
//  AddNewGroup.m
//  Lightning
//
//  Created by Cyril Gabathuler on 24.03.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import "AddNewGroup.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@implementation AddNewGroup

@synthesize groupName;


/*- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		
		self.backgroundColor = [UIColor groupTableViewBackgroundColor];
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 300, 30)];
		
		label.text = @"Enter your group name";
		
		[self addSubview:label];
		[label release];
		
		UITextField *groupName = [[UITextField alloc]initWithFrame:CGRectMake(0, 30, 300, 30)];
		groupName.placeholder = @"Group name";
		groupName.borderStyle = UITextBorderStyleRoundedRect;
		
		[self addSubview:groupName];
		[groupName release];
    }
    return self;
}*/

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	
	UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 46, 300, 30)];
	
	label.text = @"Enter your group name";
	label.backgroundColor = [UIColor clearColor];
	
	[self.view addSubview:label];
	[label release];
	
	self.groupName = [[UITextField alloc]initWithFrame:CGRectMake(0, 76, 300, 30)];
	groupName.placeholder = @"Group name";
	groupName.borderStyle = UITextBorderStyleRoundedRect;
	groupName.delegate = self;
	
	[self.view addSubview:groupName];
	[groupName release];
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[button	addTarget:self action:@selector(addUser) forControlEvents:UIControlEventTouchUpInside];
	button.frame = CGRectMake(0, 200, 300, 40);
	[button setTitle:@"Add user" forState:UIControlStateNormal];
	
	[self.view addSubview:button];
	
	
}

- (void)addUser {
	NSLog(@"addUser");
	
	MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
	mailComposer.mailComposeDelegate = self;
	
	NSString *subject = [NSString stringWithFormat:@"Group invite for groupname: %@", groupName.text];
	[mailComposer setSubject:subject];
	
	// Fill out the email body text
	NSString *emailBody = @"This is an group invite bla bla";
	[mailComposer setMessageBody:emailBody isHTML:NO];
	
	[self presentModalViewController:mailComposer animated:YES];
    [mailComposer release];
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
	
	
	[self dismissModalViewControllerAnimated:YES];
}



- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	return YES;
}


- (void)dealloc {
	[groupName release];
    [super dealloc];
}


@end
