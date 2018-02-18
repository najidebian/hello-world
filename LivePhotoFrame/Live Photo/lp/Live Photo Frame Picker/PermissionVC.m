//
//  ViewController.m
//  Live Photo Frame Picker
//
//  Created by Marwan Harb on 6/7/17.
//  Copyright © 2017 Apps & Games. All rights reserved.
//

#import "PermissionVC.h"
#import <Photos/Photos.h>
#import "Utils.h"
#import "LivePhotoPickerVC.h"

@interface PermissionVC ()

@end

@implementation PermissionVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initVars];
}

-(void) initVars
{
    _btnPermission.layer.backgroundColor = [Utils colorFromHexString:@COLOUR_PERMISSION_VC_BUTTON_BG].CGColor;
    _btnPermission.layer.cornerRadius = 20;
    [_btnPermission setTitleColor:[Utils colorFromHexString:@COLOUR_PERMISSION_VC_BUTTON_TEXT] forState:UIControlStateNormal];
	
	_lblPermission.text = NSLocalizedString(@"DOES_NOT_HAVE_ACCESS", @"App does not have access");
	[_btnPermission setTitle:NSLocalizedString(@"ALLOW", @"Allow") forState:UIControlStateNormal];
	
//	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_gradient"]];
	
	
//    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"hasDenied"])
//    {
//        _lblPermission.text = NSLocalizedString(@"GRANT_ACCESS_STATEMENT", @"Ask the user to grant access");
//        [_btnPermission setTitle:NSLocalizedString(@"GRANT_ACCESS_TITLE", @"Grant Access") forState:UIControlStateNormal];
//    }
//    else
//    {
//        _lblPermission.text = NSLocalizedString(@"APP_SETTINGS_STATEMENT", @"Ask User to allow access from the settings");
//        [_btnPermission setTitle:NSLocalizedString(@"APP_SETTINGS_TITLE", @"App Settings") forState:UIControlStateNormal];
//    }
}

-(void) showPermissionAlert
{
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"hasDenied"])
    {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status)
         {
             if (status == PHAuthorizationStatusAuthorized)
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self dismissViewControllerAnimated:YES completion:nil];
                 });
             }
             else
             {
                 [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasDenied"];
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
					 _lblPermission.text = NSLocalizedString(@"DOES_NOT_HAVE_ACCESS", @"App does not have access");
					 [_btnPermission setTitle:NSLocalizedString(@"ALLOW", @"Allow") forState:UIControlStateNormal];
                 });
             }
         }];
    }
    else
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)btnAllow:(id)sender
{
    [self showPermissionAlert];
}

@end
