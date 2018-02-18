//
//  LivePhotoPickerVC.h
//  Live Photo Frame Picker
//
//  Created by Marwan Harb on 6/7/17.
//  Copyright © 2017 Apps & Games. All rights reserved.
//

#import <UIKit/UIKit.h>

@import Photos;
@import PhotosUI;
@import MKDropdownMenu;

@interface LivePhotoPickerVC : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, PHPhotoLibraryChangeObserver>

@property (strong, nonatomic) IBOutlet UICollectionView *cvLivePhotos;
@property (strong, nonatomic) IBOutlet MKDropdownMenu *ddAlbumMenus;
@property (strong, nonatomic) IBOutlet UIView *vLoading;

- (IBAction)btnSettings:(id)sender;

@end
