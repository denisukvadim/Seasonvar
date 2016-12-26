//
//  DEMOHomeViewController.h
//  REFrostedViewControllerStoryboards
//
//  Created by Roman Efimov on 10/9/13.
//  Copyright (c) 2013 Roman Efimov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "REFrostedViewController/REFrostedViewController.h"
#import "ContentManager.h"
#import "SerialModel.h"

@interface NewsSerialViewCntroller : UICollectionViewController <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *searchField;
- (IBAction)showMenu;
- (IBAction)searchButton:(id)sender;
-(void)menuSerial:(ItemMenu)typeMenu;
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
@end
