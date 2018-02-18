//
//  MessagesViewController.h
//  Live Photo Frame Picker iMessage
//
//  Created by Marwan Harb on 6/14/17.
//  Copyright © 2017 Apps & Games. All rights reserved.
//

#import <Messages/Messages.h>

@import Photos;
@import PhotosUI;
@import MKDropdownMenu;

@interface IMMainVC : MSMessagesAppViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>

/*********** Main container ***********/
@property (strong, nonatomic) IBOutlet UIView *vContainer;

/*********** Navigation bar ***********/
@property (strong, nonatomic) IBOutlet UIView *vNavBar;
@property (strong, nonatomic) IBOutlet UILabel *lblNavBarTitle;
@property (strong, nonatomic) IBOutlet UIButton *btnNavBarRight;
@property (strong, nonatomic) IBOutlet MKDropdownMenu *ddAlbumMenus;
- (IBAction)btnNavBarRightAction:(id)sender;

/*********** Toolbar ***********/
@property (strong, nonatomic) IBOutlet UIStackView *svToolbar;
@property (strong, nonatomic) IBOutlet UIButton *btnGifOutlet;
@property (strong, nonatomic) IBOutlet UIButton *btnMovOutlet;
@property (strong, nonatomic) IBOutlet UIButton *btnFrameOutlet;
- (IBAction)btnGifAction:(id)sender;
- (IBAction)btnMovAction:(id)sender;
- (IBAction)btnFrameAction:(id)sender;

/*********** First view - Live Photo Picker ***********/
@property (strong, nonatomic) IBOutlet UIView *vLivePhotoContainer;
@property (strong, nonatomic) IBOutlet UICollectionView *cvLivePhotos;

/*********** Third view - Frame Picker ***********/
@property (strong, nonatomic) IBOutlet UIView *vFramePickerContainer;
@property (strong, nonatomic) IBOutlet UIView *vCVFramePicker;
@property (strong, nonatomic) IBOutlet UIView *vFramePickerExport;
@property (strong, nonatomic) IBOutlet UIView *vLoading;
//@property (strong, nonatomic) IBOutlet UIView *vFrameIndicator;
@property (strong, nonatomic) IBOutlet UIButton *btnExportFrame;
@property (strong, nonatomic) IBOutlet UICollectionView *cvFramePicker;
@property (strong, nonatomic) IBOutlet UIImageView *ivFrame;
@property (strong, nonatomic) IBOutlet UIImageView *ivFrameIndicator;
- (IBAction)btnExportFrameAction:(id)sender;

@end
