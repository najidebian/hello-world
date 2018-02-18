//
//  LivePhotoPickerVC.m
//  Live Photo Frame Picker
//
//  Created by Marwan Harb on 6/7/17.
//  Copyright © 2017 Apps & Games. All rights reserved.
//

#import "LivePhotoPickerVC.h"
#import <Photos/Photos.h>
#import "LivePhotoCVCell.h"
#import "Utils.h"
#import "PreviewVC.h"
#import "LivePhotoModel.h"

@import Photos;
@import PhotosUI;
@import AdobeCreativeSDKCore;

@interface LivePhotoPickerVC ()
{
    NSMutableArray *phAssetIds;
    PHLivePhotoView* photoView;
    NSIndexPath* ip;
	BOOL previewOpen;
	BOOL didRemove;
    NSString* album;
    NSMutableArray<NSString*>* albumTitles;
    
    NSMutableArray<LivePhotoModel*>* data;
}

@end

@implementation LivePhotoPickerVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _vLoading.hidden = YES;

    if (@available(iOS 11.0, *))
    {
        _cvLivePhotos.contentInsetAdjustmentBehavior = NO;
    }
    else
    {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    UINavigationBar *bar = [self.navigationController navigationBar];
    
    [self adobeAuth];
    
    [PHPhotoLibrary.sharedPhotoLibrary registerChangeObserver:self];
	
	[bar setTranslucent:NO];
    [bar setTitleTextAttributes:@{NSForegroundColorAttributeName:[Utils colorFromHexString:@COLOUR_NAVBAR_TITLE],NSFontAttributeName:[UIFont fontWithName:@"candara" size:26]}];
	
	[[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"candara" size:20]} forState:UIControlStateNormal];
	
//	self.navigationController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStyleDone target:self action:@selector(settings)];

	UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStylePlain target:self action:@selector(settings)];
	self.navigationItem.rightBarButtonItem = settingsButton;
	
    [bar setBarTintColor:[Utils colorFromHexString:@COLOUR_NAVBAR_BG]];
    [bar setTintColor:[Utils colorFromHexString:@COLOUR_NAVBAR_TINT]];
    self.view.backgroundColor = [Utils colorFromHexString:@COLOUR_LIVE_PHOTO_PICKER_VC_BG];
    
    album = @"Live Photos";
    self.ddAlbumMenus.tintColor = [Utils colorFromHexString:@COLOUR_NAVBAR_TITLE];
    self.ddAlbumMenus.backgroundDimmingOpacity = 0.6;
    self.ddAlbumMenus.rowTextAlignment = NSTextAlignmentCenter;
    self.ddAlbumMenus.dropdownRoundedCorners = UIRectCornerBottomLeft|UIRectCornerBottomRight;
    self.ddAlbumMenus.componentTextAlignment = NSTextAlignmentCenter;
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.3;
    lpgr.delegate = self;
    lpgr.delaysTouchesBegan = YES;
    [self.cvLivePhotos addGestureRecognizer:lpgr];
    
    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
    if ([statusBar respondsToSelector:@selector(setBackgroundColor:)])
    {
        statusBar.backgroundColor = [Utils colorFromHexString:@COLOUR_NAVBAR_BG];
    }
    
    [self checkGalleryPermission];
}

-(void)photoLibraryDidChange:(PHChange *)changeInstance
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self checkGalleryPermission];
    });
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[self navigationController] setNavigationBarHidden:NO animated:NO];
}

-(void) settings
{
    
}

- (IBAction)btnSettings:(id)sender
{
    
}

-(void) adobeAuth
{
    [[AdobeUXAuthManager sharedManager] setAuthenticationParametersWithClientID:@API_CLIENT_ID clientSecret:@CLIENT_SECRET additionalScopeList:@[AdobeAuthManagerUserProfileScope, AdobeAuthManagerEmailScope, AdobeAuthManagerAddressScope]];
    [AdobeUXAuthManager sharedManager].redirectURL = [NSURL URLWithString:@REDIRECT_URL];
}

-(void)viewWillAppear:(BOOL)animated
{
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
//    [self checkGalleryPermission];
}

-(void) checkGalleryPermission
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    if (status != PHAuthorizationStatusAuthorized)
    {
        [self gotoPermission];
    }
    else
    {
        [self initLivePhotoPickerClass];
    }
}

-(void) gotoPermission
{
    [self performSegueWithIdentifier:@"mainToPermissions" sender:self];
}

-(void) initLivePhotoPickerClass
{
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

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return phAssetIds.count;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(collectionView.frame.size.width / 3 - 8, collectionView.frame.size.width / 3 - 8);
}

-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ip = indexPath;
    
    [self performSegueWithIdentifier:@"livePhotosToPreview" sender:self];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    LivePhotoCVCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"livePhotoCell" forIndexPath:indexPath];
    
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

-(void) addViews:(UILongPressGestureRecognizer *)gestureRecognizer
{
	previewOpen = YES;
	
	CGPoint p = [gestureRecognizer locationInView:self.cvLivePhotos];
	
	NSIndexPath *indexPath = [self.cvLivePhotos indexPathForItemAtPoint:p];
	LivePhotoCVCell* cell = [_cvLivePhotos dequeueReusableCellWithReuseIdentifier:@"livePhotoCell" forIndexPath:indexPath];
	
	PHAsset* as = [[PHAsset fetchAssetsWithLocalIdentifiers:@[phAssetIds[indexPath.row]] options:nil] firstObject];
	
	[[PHImageManager defaultManager] requestLivePhotoForAsset:as targetSize:self.view.frame.size contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info)
	 {
		 if(info.count <= 0)
		 {
			 UIBlurEffect* beBlur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
			 UIVisualEffectView* vevBlur = [[UIVisualEffectView alloc] initWithEffect:beBlur];
			 [vevBlur setFrame:[UIScreen mainScreen].bounds];
			 vevBlur.tag = 102;
			 vevBlur.alpha = 0;
			 [[UIApplication sharedApplication].keyWindow addSubview:vevBlur];
			 
			 if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
			 {
				 photoView = [[PHLivePhotoView alloc] initWithFrame:CGRectMake(40, 40, [UIScreen mainScreen].bounds.size.width - 80, [UIScreen mainScreen].bounds.size.height - 80)];
			 }
			 else
			 {
				 photoView = [[PHLivePhotoView alloc] initWithFrame:CGRectMake(20, 20, [UIScreen mainScreen].bounds.size.width - 40, [UIScreen mainScreen].bounds.size.height - 40)];
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
			 
			 [[UIApplication sharedApplication].keyWindow addSubview:photoView];
			 
			 [UIView animateWithDuration:0.2
								   delay:0.0
								 options:UIViewAnimationOptionCurveEaseInOut
							  animations:^{
								  photoView.transform = CGAffineTransformIdentity;
								  vevBlur.alpha = 1;
								  if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
								  {
									  photoView.frame = CGRectMake(40, 40, [UIScreen mainScreen].bounds.size.width - 80, [UIScreen mainScreen].bounds.size.height - 80);
								  }
								  else
								  {
									  photoView.frame = CGRectMake(20, 40, [UIScreen mainScreen].bounds.size.width - 40, [UIScreen mainScreen].bounds.size.height - 60);
								  }
							  }
							  completion:^(BOOL finished)
			  {
				  if (didRemove)
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

-(void) removeViews
{
	[self.view.layer removeAllAnimations];
	[UIView animateWithDuration:0.2
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 [[UIApplication sharedApplication].keyWindow viewWithTag:102].alpha = 0;
						 photoView.transform = CGAffineTransformMakeScale(0.1, 0.1);
						 photoView.alpha = 0;
					 }
					 completion:^(BOOL finished)
	 {
		 [[[UIApplication sharedApplication].keyWindow viewWithTag:101] removeFromSuperview];
		 [[[UIApplication sharedApplication].keyWindow viewWithTag:102] removeFromSuperview];
		 
		 [photoView stopPlayback];
		 previewOpen = NO;
		 didRemove = NO;
	 }];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier  isEqual: @"livePhotosToPreview"])
    {
        PreviewVC* vc = segue.destinationViewController;
        vc.assetID = phAssetIds[ip.row];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
@end
