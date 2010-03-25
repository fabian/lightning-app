//
//  AddNewGroup.h
//  Lightning
//
//  Created by Cyril Gabathuler on 24.03.10.
//  Copyright 2010 Bahnhofstrasse 24, 5400 Baden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>


@interface AddNewGroup : UIViewController<UITextFieldDelegate, MFMailComposeViewControllerDelegate> {

	UITextField *groupName;
}

@property (nonatomic, retain) UITextField *groupName;

@end
