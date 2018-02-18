//
//  ViewController.h
//  Live Photo Frame Picker
//
//  Created by Marwan Harb on 6/7/17.
//  Copyright © 2017 Apps & Games. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PermissionVC : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *lblPermission;
@property (strong, nonatomic) IBOutlet UIButton *btnPermission;

- (IBAction)btnAllow:(id)sender;

@end

