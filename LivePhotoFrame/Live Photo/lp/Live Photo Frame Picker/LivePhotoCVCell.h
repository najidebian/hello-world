//
//  LivePhotoCVCell.h
//  Live Photo Frame Picker
//
//  Created by Marwan Harb on 6/7/17.
//  Copyright © 2017 Apps & Games. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Photos;
@import PhotosUI;

@interface LivePhotoCVCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView *ivLivePhotoImgPreview;
@property (strong, nonatomic) IBOutlet UIImageView *ivLivePhotoImg;
@property (strong, nonatomic) IBOutlet PHLivePhotoView *lpvLivePhoto;

@end
