//
//  FramePickerVC.h
//  Live Photo Frame Picker
//
//  Created by Marwan Harb on 6/9/17.
//  Copyright © 2017 Apps & Games. All rights reserved.
//

#import <UIKit/UIKit.h>

@import AdobeCreativeSDKCore;
@import AdobeCreativeSDKImage;

@interface FramePickerVC : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, AdobeUXImageEditorViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIView *vToolbar;
@property (strong, nonatomic) IBOutlet UIView *vContainer;
@property (strong, nonatomic) IBOutlet UIView *vFramesContainer;
@property (strong, nonatomic) IBOutlet UIView *vToast;
@property (strong, nonatomic) IBOutlet UIImageView *ivFrameIndicator;

@property (strong, nonatomic) IBOutlet UIButton *btnExportFrame;

@property (strong, nonatomic) IBOutlet UICollectionView *cvFramePicker;

@property (strong, nonatomic) IBOutlet UIImageView *ivFrame;

@property (strong, nonatomic) NSString *assetID;

- (IBAction)btnExport:(id)sender;

@end
