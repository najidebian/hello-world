//
//  MessagesViewController.m
//  Live Photo Frame Picker iMessage
//
//  Created by Marwan Harb on 6/14/17.
//  Copyright © 2017 Apps & Games. All rights reserved.
//

#import "IMMainVC.h"
#import "IMLivePhotoCVCell.h"
#import "IMFramePickerVCCell.h"
#import "IMUtils.h"
#import "LivePhotoModel.h"

@import Photos;
@import PhotosUI;
@import UIGifImage;
@import NSGIF;
@import MKDropdownMenu;


@interface IMMainVC ()
{
    NSMutableArray *phAssetIds;
    PHLivePhotoView* photoView;
    NSIndexPath* ip;
	NSIndexPath* lastSelectedIP;
    NSString* assetId;
    NSInteger viewState;
	PHAsset* asset;
	PHAsset* asset2;
    BOOL gifComplete;
    NSURL* gifURL;
	BOOL enableFramePickerCollectionView;
	NSMutableArray* imageArray;
	NSUInteger count;
	
	BOOL isOptionMenuOpen;
	BOOL previewOpen;
	BOOL didRemove;
	IMLivePhotoCVCell* lastCell;
    
    NSString* album;
    NSMutableArray<NSString*>* albumTitles;
    
    NSMutableArray<LivePhotoModel*>* data;
}
@end

@implementation IMMainVC

- (void)viewDidLoad
{
	[super viewDidLoad];
	
    viewState = 0;

    /*********** Initializing background and navigation bar colours ***********/
    _vNavBar.backgroundColor = [IMUtils colorFromHexString:@COLOUR_NAVBAR_BG];
    _lblNavBarTitle.textColor = [IMUtils colorFromHexString:@COLOUR_NAVBAR_TITLE];
//    [_btnNavBarLeft setTintColor:[IMUtils colorFromHexString:@COLOUR_NAVBAR_TITLE]];
    [_btnNavBarRight setTintColor:[IMUtils colorFromHexString:@COLOUR_NAVBAR_TITLE]];
    _vContainer.backgroundColor = [IMUtils colorFromHexString:@COLOUR_LIVE_PHOTO_PICKER_VC_BG];
	self.view.backgroundColor = [IMUtils colorFromHexString:@COLOUR_LIVE_PHOTO_PICKER_VC_BG];
	
	_btnFrameOutlet.backgroundColor = [IMUtils colorFromHexString:@COLOUR_PREVIEW_VC_TOOLBAR_BUTTON_BG];
	_btnFrameOutlet.titleLabel.adjustsFontSizeToFitWidth = YES;
	_btnFrameOutlet.layer.cornerRadius = 5;
	
	CGFloat size = _btnFrameOutlet.titleLabel.font.pointSize;
	
	_btnGifOutlet.backgroundColor = [IMUtils colorFromHexString:@COLOUR_PREVIEW_VC_TOOLBAR_BUTTON_BG];
	[_btnGifOutlet.titleLabel setFont:[UIFont fontWithName:@"OCR A Std" size:size]];
	_btnGifOutlet.layer.cornerRadius = 5;
	
	_btnMovOutlet.backgroundColor = [IMUtils colorFromHexString:@COLOUR_PREVIEW_VC_TOOLBAR_BUTTON_BG];
	[_btnMovOutlet.titleLabel setFont:[UIFont fontWithName:@"OCR A Std" size:size]];
	_btnMovOutlet.layer.cornerRadius = 5;
	
	_svToolbar.hidden = YES;
	isOptionMenuOpen = NO;
    
    _lblNavBarTitle.hidden = YES;
    _ddAlbumMenus.hidden = NO;
	
	_vLivePhotoContainer.hidden = NO;
	_vFramePickerContainer.hidden = YES;
	
	_cvLivePhotos.delegate = self;
	_cvFramePicker.delegate = self;
	_cvLivePhotos.dataSource = self;
	_cvFramePicker.dataSource = self;
	
	_vLoading.hidden = YES;
	
	enableFramePickerCollectionView = NO;
	
    [self initLivePhotoPickerView];
}

-(void)viewDidAppear:(BOOL)animated
{
	_cvLivePhotos.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
}

/******************************************************************/
/******************************************************************/
/********* Below section is for the live photo picker view ********/
/******************************************************************/
/******************************************************************/

/*********** Initializes all components to do with the live photo picker section ***********/
-(void) initLivePhotoPickerView
{
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.3;
    lpgr.delegate = self;
    lpgr.delaysTouchesBegan = YES;
    [self.cvLivePhotos addGestureRecognizer:lpgr];
    
    album = @"Live Photos";
    self.ddAlbumMenus.tintColor = [IMUtils colorFromHexString:@COLOUR_NAVBAR_TITLE];
    self.ddAlbumMenus.backgroundDimmingOpacity = 0.6;
    self.ddAlbumMenus.rowTextAlignment = NSTextAlignmentCenter;
    self.ddAlbumMenus.dropdownRoundedCorners = UIRectCornerBottomLeft|UIRectCornerBottomRight;
    self.ddAlbumMenus.componentTextAlignment = NSTextAlignmentCenter;
    
    _vContainer.backgroundColor = [IMUtils colorFromHexString:@COLOUR_LIVE_PHOTO_PICKER_VC_BG];
    
//    _btnNavBarLeft.hidden = YES;
//    _btnNavBarLeft.enabled = NO;
    
    _btnNavBarRight.hidden = YES;
    _btnNavBarRight.enabled = NO;
    
//    [self getAllPhotosFromGallery];
    [self loadAlbums];
}

-(void)loadAlbums
{
    albumTitles = [[NSMutableArray alloc] init];
    data = [[NSMutableArray alloc] init];

    _vLoading.hidden = NO;

    //Getting smart albums
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];

    [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.predicate = [NSPredicate predicateWithFormat: @"(mediaSubtype == %ld)", PHAssetMediaSubtypePhotoLive];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey: @"creationDate" ascending: NO]];

        PHFetchResult<PHAsset *> *assetsFetchResults = [PHAsset fetchAssetsInAssetCollection:collection options:options];

        if(assetsFetchResults.count > 0)
        {
            if(![collection.localizedTitle isEqualToString:@"Recently Deleted"])
            {
                for (PHAsset *asset in assetsFetchResults)
                {
                    [data addObject:[[LivePhotoModel alloc] initWithAlbumName:collection.localizedTitle andAssetId:asset.localIdentifier]];
                }

                [albumTitles addObject:collection.localizedTitle];
            }
        }

        [_ddAlbumMenus reloadAllComponents];
    }];

    //Getting user created albums
    PHFetchOptions *userAlbumsOptions = [PHFetchOptions new];
    userAlbumsOptions.predicate = [NSPredicate predicateWithFormat:@"estimatedAssetCount > 0"];

    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:userAlbumsOptions];

    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.predicate = [NSPredicate predicateWithFormat: @"(mediaSubtype == %ld)", PHAssetMediaSubtypePhotoLive];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey: @"creationDate" ascending: NO]];

        PHFetchResult<PHAsset *> *assetsFetchResults = [PHAsset fetchAssetsInAssetCollection:collection options:options];

        if(assetsFetchResults.count > 0)
        {
            if(![collection.localizedTitle isEqualToString:@"Recently Deleted"])
            {
                for (PHAsset *asset in assetsFetchResults)
                {
                    [data addObject:[[LivePhotoModel alloc] initWithAlbumName:collection.localizedTitle andAssetId:asset.localIdentifier]];
                }

                [albumTitles addObject:collection.localizedTitle];
            }
        }

        [_ddAlbumMenus reloadAllComponents];
    }];

    [_ddAlbumMenus reloadAllComponents];
    [self populateCVWithAlbum];

    _vLoading.hidden = YES;
}

- (NSInteger) numberOfComponentsInDropdownMenu:(MKDropdownMenu *) dropdownMenu
{
    return 1;
}

- (NSInteger)dropdownMenu:(MKDropdownMenu *)dropdownMenu numberOfRowsInComponent:(NSInteger)component
{
    return albumTitles.count;
}

-(void) dropdownMenu:(MKDropdownMenu*) dropdownMenu didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if(isOptionMenuOpen)
    {
        [UIView animateWithDuration:0.1 animations:^{
            _svToolbar.center = CGPointMake(_svToolbar.center.x, -(_svToolbar.frame.size.height / 2));
        }];
    }
    
    album = albumTitles[row];
    [self populateCVWithAlbum];
    
    [dropdownMenu closeAllComponentsAnimated:YES];
    [_ddAlbumMenus reloadAllComponents];
}

- (NSAttributedString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu attributedTitleForComponent:(NSInteger)component
{
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString: @"Album: " attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:20 weight:UIFontWeightLight], NSForegroundColorAttributeName: [UIColor whiteColor]}];
    
    [string appendAttributedString: [[NSAttributedString alloc] initWithString:album attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:20 weight:UIFontWeightMedium], NSForegroundColorAttributeName: [UIColor whiteColor]}]];
    
    return string;
}

- (NSAttributedString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString: albumTitles[row] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:20 weight:UIFontWeightMedium], NSForegroundColorAttributeName: [UIColor blackColor]}];
    
    return string;
}

-(void)populateCVWithAlbum
{
    _vLoading.hidden = NO;
    
    phAssetIds = [[NSMutableArray alloc]init];
    [phAssetIds removeAllObjects];
    
    [data enumerateObjectsUsingBlock:^(LivePhotoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj.getAlbumName isEqualToString:album])
        {
            [phAssetIds addObject:obj.getAssetId];
        }
    }];
    
    [_cvLivePhotos reloadData];
    
    _vLoading.hidden = YES;
}

/*********** Gets all live photos from the gallery and stores the asset identifiers in an array ***********/
-(void)getAllPhotosFromGallery
{
    phAssetIds = [[NSMutableArray alloc]init];
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.predicate = [NSPredicate predicateWithFormat: @"(mediaSubtype == %ld)", PHAssetMediaSubtypePhotoLive];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey: @"creationDate" ascending: NO]];
    
    PHFetchResult<PHAsset *> *assetsFetchResults = [PHAsset fetchAssetsWithMediaType: PHAssetMediaTypeImage options: options];
    
    for (PHAsset *ass in assetsFetchResults)
    {
        [phAssetIds addObject:ass.localIdentifier];
    }
    
    [_cvLivePhotos reloadData];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	if(collectionView == _cvLivePhotos)
	{
		return phAssetIds.count;
	}
	else
	{
		return imageArray.count;
	}
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	if(collectionView == _cvLivePhotos)
	{
		return CGSizeMake(collectionView.frame.size.width / 3 - 8, collectionView.frame.size.width / 3 - 8);
	}
	else
	{
		return CGSizeMake(collectionView.frame.size.height, collectionView.frame.size.height);
	}
}

-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	if(collectionView == _cvLivePhotos)
	{
		lastCell.layer.borderWidth = 0;
		
		asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[phAssetIds[indexPath.row]] options:nil] firstObject];
		
		IMLivePhotoCVCell* cell = (IMLivePhotoCVCell*)[_cvLivePhotos cellForItemAtIndexPath:indexPath];
		cell.layer.borderWidth = 3;
		cell.layer.borderColor = [IMUtils colorFromHexString:@COLOUR_LIVE_PHOTO_PICKER_CELL_BORDER].CGColor;
		
		lastCell = cell;
		
		_svToolbar.hidden = NO;
		if(isOptionMenuOpen)
		{
			[UIView animateWithDuration:0.1 animations:^{
				_svToolbar.center = CGPointMake(_svToolbar.center.x, -(_svToolbar.frame.size.height / 2));
			} completion:^(BOOL finished)
			{
				[UIView animateWithDuration:0.1 animations:^{
					_svToolbar.center = CGPointMake(_svToolbar.center.x, _svToolbar.frame.size.height / 2);
				}];
			}];
		}
		else
		{
			_svToolbar.center = CGPointMake(_vContainer.frame.size.width / 2, -(_svToolbar.frame.size.height / 2));
			
			[UIView animateWithDuration:0.1 animations:^{
				_svToolbar.center = CGPointMake(_svToolbar.center.x, _svToolbar.frame.size.height / 2);
			} completion:^(BOOL finished)
			{
				isOptionMenuOpen = YES;
			}];
		}
		
//		[self initPreviewView];
	}
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	if(collectionView == _cvLivePhotos)
	{
		IMLivePhotoCVCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"livePhotoCell" forIndexPath:indexPath];
		
		PHAsset* as = [[PHAsset fetchAssetsWithLocalIdentifiers:@[phAssetIds[indexPath.row]] options:nil] firstObject];
		
		[[PHImageManager defaultManager] requestImageForAsset:as targetSize:cell.bounds.size contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info)
		 {
			 if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
			 {
				 cell.ivLivePhotoImg.frame = CGRectMake(0, 0, cell.frame.size.width / 8, cell.frame.size.height / 8);
			 }
			 else{
				 cell.ivLivePhotoImg.frame = CGRectMake(0, 0, cell.frame.size.width / 4, cell.frame.size.height / 4);
			 }
			 
			 cell.ivLivePhotoImg.image = [PHLivePhotoView livePhotoBadgeImageWithOptions:PHLivePhotoBadgeOptionsOverContent];
			 cell.ivLivePhotoImgPreview.image = result;
			 
			 cell.layer.cornerRadius = 5;
		 }];
		
		return cell;
	}
	else
	{
		IMFramePickerVCCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"frameCell" forIndexPath:indexPath];
		
		cell.ivFrame.image = [self makeUIImageFromCIImage:[imageArray objectAtIndex:indexPath.row]];
		
		return cell;
	}
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	float xOffset = scrollView.contentOffset.x + ((_cvFramePicker.frame.size.width / 2));
	
	if(scrollView.contentOffset.x < 0)
	{
		float percent = -(scrollView.contentOffset.x * 100) / (_cvFramePicker.frame.size.height / 2);
		_ivFrameIndicator.alpha = (100 - percent) / 100;
	}
	
	if(scrollView.contentOffset.x > (_cvFramePicker.contentSize.width - _cvFramePicker.frame.size.width))
	{
		float percent = ((scrollView.contentOffset.x - (_cvFramePicker.contentSize.width - _cvFramePicker.frame.size.width)) * 100) / (_cvFramePicker.frame.size.height / 2);
		_ivFrameIndicator.alpha = (100 - percent) / 100;
	}
	
	if(scrollView.contentOffset.x >= 0 && scrollView.contentOffset.x < (_cvFramePicker.contentSize.width - _cvFramePicker.frame.size.width))
	{
		CGPoint p = [_cvFramePicker convertPoint:CGPointMake(xOffset, 0) toView:_cvFramePicker];
		NSIndexPath* ip2 = [_cvFramePicker indexPathForItemAtPoint:p];
		_ivFrame.image = [self makeUIImageFromCIImage:[imageArray objectAtIndex:ip2.row]];
	}
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
	if(collectionView == _cvFramePicker)
	{
		return UIEdgeInsetsMake(0, ((_cvFramePicker.frame.size.width / 2) - (_cvFramePicker.frame.size.height / 2)), 0, ((_cvFramePicker.frame.size.width / 2) - (_cvFramePicker.frame.size.height / 2)));
	}
	else
	{
		return UIEdgeInsetsMake(8, 6, 8, 6);
	}
}

/*********** Adding long press to each cell which adds a view and shows the live photo playing as a preview ***********/
-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
	//Adding longpress here to stop the cell click going to next view controller
	
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan && !previewOpen)
	{
		[self addViews:gestureRecognizer];
	}
	
	if(gestureRecognizer.state == UIGestureRecognizerStateEnded && previewOpen)
	{
		didRemove = YES;
		[self removeViews];
	}
}

-(void) addViews:(UILongPressGestureRecognizer*) gestureRecognizer
{
	previewOpen = YES;
	
	CGPoint p = [gestureRecognizer locationInView:self.cvLivePhotos];
	
	NSIndexPath *indexPath = [self.cvLivePhotos indexPathForItemAtPoint:p];
	IMLivePhotoCVCell* cell = [_cvLivePhotos dequeueReusableCellWithReuseIdentifier:@"livePhotoCell" forIndexPath:indexPath];
	
	PHAsset* as = [[PHAsset fetchAssetsWithLocalIdentifiers:@[phAssetIds[indexPath.row]] options:nil] firstObject];
	
	[[PHImageManager defaultManager] requestLivePhotoForAsset:as targetSize:self.view.frame.size contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info)
	 {
		 if(info.count <= 0)
		 {
			 UIBlurEffect* beBlur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
			 UIVisualEffectView* vevBlur = [[UIVisualEffectView alloc] initWithEffect:beBlur];
			 [vevBlur setFrame:self.view.bounds];
			 vevBlur.tag = 102;
			 vevBlur.alpha = 0;
			 [_vContainer addSubview:vevBlur];
			 
			 if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
			 {
				 photoView = [[PHLivePhotoView alloc] initWithFrame:CGRectMake(40, 40, _vContainer.frame.size.width - 80, _vContainer.frame.size.height - 80)];
			 }
			 else
			 {
				 photoView = [[PHLivePhotoView alloc] initWithFrame:CGRectMake(20, 20, _vContainer.frame.size.width - 40, _vContainer.frame.size.height - 40)];
			 }
			 
			 photoView.livePhoto = livePhoto;
			 photoView.contentMode = UIViewContentModeScaleAspectFill;
			 photoView.tag = 101;
			 photoView.layer.cornerRadius = 15;
			 photoView.clipsToBounds = YES;
			 photoView.layer.shadowOffset = CGSizeMake(10, 10);
			 photoView.layer.shadowColor = [UIColor blackColor].CGColor;
			 photoView.transform = CGAffineTransformMakeScale(0.1, 0.1);
			 photoView.center = cell.center;
			 
			 [_vContainer addSubview:photoView];
			 
			 [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
				 photoView.transform = CGAffineTransformIdentity;
				 vevBlur.alpha = 1;
				 if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
				 {
					 photoView.frame = CGRectMake(40, 40, _vContainer.frame.size.width - 80, _vContainer.frame.size.height - 80);
				 }
				 else
				 {
					 photoView.frame = CGRectMake(20, 20, _vContainer.frame.size.width - 40, _vContainer.frame.size.height - 40);
				 }
			 }
							  completion:^(BOOL finished)
			  {
				  if(didRemove)
				  {
					  [self removeViews];
				  }
				  else
				  {
					  [photoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
				  }
			  }];
		 }
	 }];
}

-(void)removeViews
{
	[self.view.layer removeAllAnimations];
	[UIView animateWithDuration:0.2
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 [_vContainer  viewWithTag:102].alpha = 0;
						 photoView.transform = CGAffineTransformMakeScale(0.1, 0.1);
						 photoView.alpha = 0;
					 }
					 completion:^(BOOL finished)
	 {
		 [[_vContainer viewWithTag:101] removeFromSuperview];
		 [[_vContainer viewWithTag:102] removeFromSuperview];
		 [photoView stopPlayback];
		 previewOpen = NO;
		 didRemove = NO;
	 }];
}

- (IBAction)btnGifAction:(id)sender
{
	_vLoading.hidden = NO;
	
	PHAssetResource* phAR = [[PHAssetResource assetResourcesForAsset:asset] lastObject];
	
	NSString* path = NSTemporaryDirectory();
	NSString* fileName = @"temp.mov";
	NSString* finalPath = [path stringByAppendingPathComponent:fileName];
	
	[IMUtils emptyTempDirectory];
	
	[[PHAssetResourceManager defaultManager] writeDataForAssetResource:phAR toFile:[NSURL fileURLWithPath:finalPath] options:nil completionHandler:^(NSError * _Nullable error)
	 {
		 if(error == NULL)
		 {
			 [NSGIF createGIFfromURL:[NSURL fileURLWithPath:finalPath] withFrameCount:20 delayTime:.10 loopCount:0 completion:^(NSURL *GifURL)
			  {
				  _vLoading.hidden = YES;
				  if(GifURL.absoluteString.length == 0)
				  {
					  UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ERROR", @"Error") message:NSLocalizedString(@"ERROR_CREATING_GIF", @"Error creating gif") preferredStyle:UIAlertControllerStyleAlert];
					  UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
					  
					  [alert addAction:defaultAction];
					  [self presentViewController:alert animated:YES completion:nil];
				  }
				  else
				  {
					  [self.activeConversation insertAttachment:GifURL withAlternateFilename:fileName completionHandler:nil];
					  [self requestPresentationStyle:MSMessagesAppPresentationStyleCompact];
					  
				  }
			  }];
		 }
		 else
		 {
			 UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ERROR", @"Error") message:NSLocalizedString(@"ERROR_CREATING_GIF", @"Error creating gif") preferredStyle:UIAlertControllerStyleAlert];
			 UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
			 
			 [alert addAction:defaultAction];
			 [self presentViewController:alert animated:YES completion:nil];
		 }
	 }];
}

- (IBAction)btnMovAction:(id)sender
{
	_vLoading.hidden = NO;
	
	PHAssetResource* phAR = [[PHAssetResource assetResourcesForAsset:asset] lastObject];
	
	NSString* path = NSTemporaryDirectory();
	NSString* fileName = @"tempVid.mp4";
	NSString* finalPath2 = [path stringByAppendingPathComponent:fileName];
	
	[IMUtils emptyTempDirectory];
	
	[[PHAssetResourceManager defaultManager] writeDataForAssetResource:phAR toFile:[NSURL fileURLWithPath:finalPath2] options:nil completionHandler:^(NSError * _Nullable error)
	 {
		 _vLoading.hidden = YES;
		 
		 [self.activeConversation insertAttachment:[NSURL fileURLWithPath:finalPath2] withAlternateFilename:fileName completionHandler:nil];
		 [self requestPresentationStyle:MSMessagesAppPresentationStyleCompact];
	 }];
}

-(void)printFolderContents:(NSString*)path
{
	NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
	NSLog(@"folderContents: %@", dirs);
}

- (IBAction)btnFrameAction:(id)sender
{
	[self initFramePickerView];
}

/******************************************************************/
/******************************************************************/
/************** Below section is for the preview view *************/
/******************************************************************/
/******************************************************************/

-(void) initFramePickerView
{
	viewState = 2;
	
	_lblNavBarTitle.text = @"Frame Picker";
    _lblNavBarTitle.hidden = NO;
    _ddAlbumMenus.hidden = YES;
	
	_btnNavBarRight.hidden = NO;
	_btnNavBarRight.enabled = YES;
	
	_vLivePhotoContainer.hidden = YES;
	_vFramePickerContainer.hidden = NO;
	
	_vLoading.backgroundColor = [IMUtils colorFromHexString:@COLOUR_FRAME_PICKER_VC_BG];
	[_btnExportFrame setTitleColor:[IMUtils colorFromHexString:@COLOUR_FRAME_PICKER_VC_TOOLBAR_BUTTON_TEXT] forState: UIControlStateNormal];
	_btnExportFrame.backgroundColor = [IMUtils colorFromHexString:@COLOUR_FRAME_PICKER_VC_TOOLBAR_BUTTON_BG];
	_btnExportFrame.layer.cornerRadius = 5;
	
	if(self.presentationStyle == MSMessagesAppPresentationStyleCompact)
	{
		[self showExpandedBlurMessageFramePicker];
	}
	
	enableFramePickerCollectionView = YES;
	
	_vFramePickerContainer.hidden = YES;
	_vLoading.hidden = NO;
//    _ivFrame.hidden = YES;
	
	[asset requestContentEditingInputWithOptions:kNilOptions completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info)
    {
		[self processLivePhoto:contentEditingInput];
	}];
}

- (void)processLivePhoto:(PHContentEditingInput *)input
{
	imageArray = [[NSMutableArray alloc]init];
	count = 0;
	
	PHLivePhotoEditingContext *context = [[PHLivePhotoEditingContext alloc] initWithLivePhotoEditingInput:input];
	context.frameProcessor = ^CIImage *(id <PHLivePhotoFrame> frame, NSError **error)
	{
		[imageArray addObject:frame.image];
		
		return frame.image;
	};
	
	PHContentEditingOutput *output = [[PHContentEditingOutput alloc] initWithContentEditingInput: input];
	[context saveLivePhotoToOutput:output options:nil completionHandler:^(BOOL success, NSError * _Nullable error)
	 {
		 if(success)
		 {
			 _vLoading.hidden = YES;
			 _vFramePickerContainer.hidden = NO;
			 
			 [imageArray removeObjectAtIndex:0];
			 [_cvFramePicker reloadData];

			 int pos = (int) imageArray.count / 2;
			 NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:pos inSection:0];
			 
			 [_cvFramePicker scrollToItemAtIndexPath:pathToLastItem atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
			 _ivFrame.image = [self makeUIImageFromCIImage:[imageArray objectAtIndex:pos]];
			 _ivFrameIndicator.alpha = 1;
//             _ivFrame.hidden = NO;
		 }
		 else
		 {
			 UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ERROR", @"Error") message:NSLocalizedString(@"ERROR_PARSING_LIVE_PHOTO", @"Error parsing livephoto") preferredStyle:UIAlertControllerStyleAlert];
			 UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
											 {
												 [self.navigationController popViewControllerAnimated:YES];
											 }];
			 
			 [alert addAction:defaultAction];
			 [self presentViewController:alert animated:YES completion:nil];
		 }
	 }];
}

-(UIImage*)makeUIImageFromCIImage:(CIImage*)ciImage
{
	CIContext* cicontext = [CIContext contextWithOptions:nil];
	UIImage * returnImage;
	
	CGImageRef processedCGImage = [cicontext createCGImage:ciImage fromRect:[ciImage extent]];
	
	returnImage = [UIImage imageWithCGImage:processedCGImage];
	CGImageRelease(processedCGImage);
	
	return returnImage;
}

/*********** Blurs the background and shows a message asking the user to switch to the expanded view ***********/
-(void) showExpandedBlurMessageFramePicker
{
	UIBlurEffect* beBlur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
	UIVisualEffectView* vevBlur = [[UIVisualEffectView alloc] initWithEffect:beBlur];
	[vevBlur setFrame:CGRectMake(0, 0, _vLivePhotoContainer.bounds.size.width, 1000)];
	//    [vevBlur setFrame:_vLivePhotoContainer.bounds];
	vevBlur.tag = 999;
	[_vFramePickerContainer addSubview:vevBlur];
	
	UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _vLivePhotoContainer.bounds.size.width, 100)];
	lbl.text = @"Please switch to the expanded view.";
	lbl.textAlignment = NSTextAlignmentCenter;
	lbl.tag = 998;
	[_vFramePickerContainer addSubview:lbl];
}

/*********** Clears the message asking the user to expand the view ***********/
-(void) clearExpandedBlurMessageFramePicker
{
	[[_vFramePickerContainer viewWithTag:999] removeFromSuperview];
	[[_vFramePickerContainer viewWithTag:998] removeFromSuperview];
}

- (IBAction)btnExportFrameAction:(id)sender
{
	NSData* data = UIImagePNGRepresentation(_ivFrame.image);
	
	NSString* path = NSTemporaryDirectory();
	NSString* finalPath = [path stringByAppendingPathComponent:@"tempImage.png"];
	
	[IMUtils removeTempFilePath:finalPath];
	
	[data writeToFile:finalPath atomically:YES];
	
	MSConversation* conv = self.activeConversation;
	[conv insertAttachment:[NSURL fileURLWithPath:finalPath] withAlternateFilename:nil completionHandler:nil];
	[self requestPresentationStyle:MSMessagesAppPresentationStyleCompact];
}

- (IBAction)btnNavBarRightAction:(id)sender
{
	if(viewState == 2)
	{
		viewState = 0;
		_lblNavBarTitle.text = @"Live Photos";
		_btnNavBarRight.hidden = YES;
		_btnNavBarRight.enabled = NO;
        
        _lblNavBarTitle.hidden = YES;
        _ddAlbumMenus.hidden = NO;
		
		_vLivePhotoContainer.hidden = NO;
		_vFramePickerContainer.hidden = YES;
		
		[self clearExpandedBlurMessageFramePicker];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Conversation Handling

-(void)didBecomeActiveWithConversation:(MSConversation *)conversation
{
    // Called when the extension is about to move from the inactive to active state.
    // This will happen when the extension is about to present UI.
    
    // Use this method to configure the extension and restore previously stored state.
}

-(void)willResignActiveWithConversation:(MSConversation *)conversation
{
    // Called when the extension is about to move from the active to inactive state.
    // This will happen when the user dissmises the extension, changes to a different
    // conversation or quits Messages.
    
    // Use this method to release shared resources, save user data, invalidate timers,
    // and store enough state information to restore your extension to its current state
    // in case it is terminated later.
}

-(void)didReceiveMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    // Called when a message arrives that was generated by another instance of this
    // extension on a remote device.
    
    // Use this method to trigger UI updates in response to the message.
}

-(void)didStartSendingMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    // Called when the user taps the send button.
}

-(void)didCancelSendingMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    // Called when the user deletes the message without sending it.
    
    // Use this to clean up state related to the deleted message.
}

-(void)willTransitionToPresentationStyle:(MSMessagesAppPresentationStyle)presentationStyle
{
    // Called before the extension transitions to a new presentation style.
    
    // Use this method to prepare for the change in presentation style.
}

-(void)didTransitionToPresentationStyle:(MSMessagesAppPresentationStyle)presentationStyle
{
    // Called after the extension transitions to a new presentation style.
    
    // Use this method to finalize any behaviors associated with the change in presentation style.
    
    if(presentationStyle == MSMessagesAppPresentationStyleCompact)
    {
		if(viewState == 2)
		{
			[self showExpandedBlurMessageFramePicker];
		}
		
		_cvLivePhotos.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    else
	{
		if(viewState == 2)
		{
			[self clearExpandedBlurMessageFramePicker];
			
			_ivFrame.frame = CGRectMake(10, 30, _vFramePickerContainer.frame.size.width - 20, _vCVFramePicker.frame.origin.y - 60);
			_ivFrame.hidden = NO;
		}
		
		_cvLivePhotos.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
}
@end
