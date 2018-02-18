//
//  PreviewVC.h
//  Live Photo Frame Picker
//
//  Created by Marwan Harb on 6/8/17.
//  Copyright © 2017 Apps & Games. All rights reserved.
//

#import <UIKit/UIKit.h>

@import Photos;
@import PhotosUI;

@interface PreviewVC : UIViewController

@property (strong, nonatomic) IBOutlet UIView *vLPVContainer;
@property (strong, nonatomic) IBOutlet UIView *vToast;
@property (strong, nonatomic) IBOutlet UIView *vCreatingGif;
@property (strong, nonatomic) IBOutlet UIView *vToolbar;
@property (strong, nonatomic) IBOutlet UIButton *btnGifOutlet;
@property (strong, nonatomic) IBOutlet UIButton *btnMovOutlet;
@property (strong, nonatomic) IBOutlet UIButton *btnFrameOutlet;
@property (strong, nonatomic) IBOutlet UILabel *lblExportAs;

@property (strong, nonatomic) IBOutlet PHLivePhotoView *lpvPreview;
@property (strong, nonatomic) IBOutlet UIImageView *ivBadge;

@property (strong, nonatomic) NSString *assetID;

- (IBAction)btnGif:(id)sender;
- (IBAction)btnMov:(id)sender;
- (IBAction)btnFrame:(id)sender;

@end
