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

@protocol AddNewGroupDelegate;

@interface AddNewGroup : UIViewController<UITextFieldDelegate, MFMailComposeViewControllerDelegate> {

	UITextField *groupName;
	id <AddNewGroupDelegate> delegate;
}

@property (nonatomic, retain) UITextField *groupName;
@property (assign) id <AddNewGroupDelegate> delegate;

- (void)doneAddGroup;

@end

@protocol AddNewGroupDelegate <NSObject>

- (void)finishAddGroup;

@end
