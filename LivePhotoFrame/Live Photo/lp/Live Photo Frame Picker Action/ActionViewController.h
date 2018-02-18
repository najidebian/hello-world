//
//  ActionViewController.h
//  Live Photo Frame Picker Action
//
//  Created by Marwan Harb on 10/3/17.
//  Copyright © 2017 Apps & Games. All rights reserved.
//

#import <UIKit/UIKit.h>

@import Photos;
@import PhotosUI;

@interface ActionViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
{
    BOOL lpFound;
    BOOL processed;
    BOOL parsingComplete;
}

@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnLeftNavbar;
@property (strong, nonatomic) IBOutlet PHLivePhotoView *vLivePhoto;
@property (weak, nonatomic) IBOutlet UILabel *lblNotLivePhoto;
@property (weak, nonatomic) IBOutlet UIImageView *ivBadge;
@property (weak, nonatomic) IBOutlet UIView *vLivePhotoContainer;
@property (weak, nonatomic) IBOutlet UIButton *btnGifOutlet;
@property (weak, nonatomic) IBOutlet UIButton *btnMovOutlet;
@property (weak, nonatomic) IBOutlet UIButton *btnFrameOutlet;
@property (weak, nonatomic) IBOutlet UIView *vToolbar;
@property (weak, nonatomic) IBOutlet UILabel *lblExportAs;
@property (weak, nonatomic) IBOutlet UIView *vToast;
@property (weak, nonatomic) IBOutlet UIView *vCreatingGif;
@property (weak, nonatomic) IBOutlet UIImageView *ivSeparator;
@property (weak, nonatomic) IBOutlet UIView *vFrameContainer;

@property (weak, nonatomic) IBOutlet UIView *vFrameToolbar;
@property (weak, nonatomic) IBOutlet UIButton *btnExportFrame;
@property (weak, nonatomic) IBOutlet UIImageView *ivFrame;
@property (weak, nonatomic) IBOutlet UICollectionView *cvFramePicker;
@property (weak, nonatomic) IBOutlet UIImageView *ivFrameIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loading;

- (IBAction)btnGif:(id)sender;
- (IBAction)btnMov:(id)sender;
- (IBAction)btnFrame:(id)sender;
- (IBAction)btnExport:(id)sender;

@end
