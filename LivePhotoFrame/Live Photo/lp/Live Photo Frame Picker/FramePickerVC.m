//
//  FramePickerVC.m
//  Live Photo Frame Picker
//
//  Created by Marwan Harb on 6/9/17.
//  Copyright © 2017 Apps & Games. All rights reserved.
//

#import "FramePickerVC.h"
#import "Utils.h"
#import "FramePickerVCCell.h"
#import <AdobeCreativeSDKCore/AdobeCreativeSDKCore.h>

@import Photos;
@import PhotosUI;
@import AdobeCreativeSDKImage;

@interface FramePickerVC ()
{
    PHAsset* asset;
    NSMutableArray* imageArray;
}

@end

@implementation FramePickerVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initVars];
}

-(void) initVars
{
//    _vToolbar.backgroundColor = [Utils colorFromHexString:@COLOUR_FRAME_PICKER_VC_TOOLBAR_BG];
    
    [_btnExportFrame setTitleColor:[Utils colorFromHexString:@COLOUR_FRAME_PICKER_VC_TOOLBAR_BUTTON_TEXT] forState:UIControlStateNormal];
	_btnExportFrame.backgroundColor = [Utils colorFromHexString:@COLOUR_FRAME_PICKER_VC_TOOLBAR_BUTTON_BG];
	_btnExportFrame.layer.cornerRadius = 5;
    
//    self.view.backgroundColor = [Utils colorFromHexString:@COLOUR_FRAME_PICKER_VC_BG];
//    _vContainer.backgroundColor = [Utils colorFromHexString:@COLOUR_FRAME_PICKER_VC_BG];
    _vContainer.hidden = YES;
	
	_vToast.layer.cornerRadius = 20;
	_vToast.alpha = 0.6;
	_vToast.hidden = YES;
    
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"DONE", @"Done") style:UIBarButtonItemStylePlain target:self action:@selector(done)];
    self.navigationItem.rightBarButtonItem = newBackButton;
    
    asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[_assetID] options:nil] firstObject];
    
    [asset requestContentEditingInputWithOptions:kNilOptions completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
        [self processLivePhoto:contentEditingInput];
    }];
}

-(void) showToast:(NSInteger)seconds
{
	[UIView transitionWithView:_vToast duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{_vToast.hidden = NO; _vToast.alpha = 1;}completion:NULL];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[UIView transitionWithView:_vToast duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{_vToast.alpha = 0;}completion:^(BOOL finished) {
			_vToast.hidden = YES;
//			[self.navigationController popViewControllerAnimated:YES];
		}];
	});
}

-(void) done
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)processLivePhoto:(PHContentEditingInput *)input
{
    imageArray = [[NSMutableArray alloc]init];
    
    PHLivePhotoEditingContext *context = [[PHLivePhotoEditingContext alloc] initWithLivePhotoEditingInput:input];
    context.frameProcessor = ^CIImage *(id <PHLivePhotoFrame> frame, NSError **error)
    {
        [imageArray addObject:[self makeUIImageFromCIImage:frame.image]];
        
        return frame.image;
    };
    
    PHContentEditingOutput *output = [[PHContentEditingOutput alloc] initWithContentEditingInput: input];
    [context saveLivePhotoToOutput:output options:nil completionHandler:^(BOOL success, NSError * _Nullable error)
     {
         if(success)
         {
             [imageArray removeObjectAtIndex:0];
             [_cvFramePicker reloadData];
             
             int pos = (int) imageArray.count / 2;
             NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:pos inSection:0];
             
             [_cvFramePicker scrollToItemAtIndexPath:pathToLastItem atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
             _ivFrame.image = [imageArray objectAtIndex:pos];
             _ivFrameIndicator.alpha = 1;
             
             _vContainer.hidden = NO;
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
    // finally!
    UIImage * returnImage;
    
    CGImageRef processedCGImage = [cicontext createCGImage:ciImage fromRect:[ciImage extent]];
    
    returnImage = [UIImage imageWithCGImage:processedCGImage];
    CGImageRelease(processedCGImage);
    
    return returnImage;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return imageArray.count;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(collectionView.frame.size.height, collectionView.frame.size.height);
}

-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FramePickerVCCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"frameCell" forIndexPath:indexPath];
    
    cell.ivFrame.image = [imageArray objectAtIndex:indexPath.row];
    
    return cell;
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
        NSIndexPath* ip = [_cvFramePicker indexPathForItemAtPoint:p];
        _ivFrame.image = [imageArray objectAtIndex:ip.row];
    }
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, ((_cvFramePicker.frame.size.width / 2) - (_cvFramePicker.frame.size.height / 2)), 0, ((_cvFramePicker.frame.size.width / 2) - (_cvFramePicker.frame.size.height / 2)));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)btnExport:(id)sender
{
    [self launchPhotoEditorWithImage:_ivFrame.image];
}

- (void)launchPhotoEditorWithImage:(UIImage*)image
{
    AdobeUXImageEditorViewController *photoEditor = [[AdobeUXImageEditorViewController alloc] initWithImage:image];
    [photoEditor setDelegate:self];
	
    [self presentViewController:photoEditor animated:YES completion:nil];
}

-(void)photoEditor:(AdobeUXImageEditorViewController *)editor finishedWithImage:(UIImage *)image
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
    activityVC.popoverPresentationController.sourceView = _vFramesContainer;
    activityVC.popoverPresentationController.sourceRect = _vFramesContainer.bounds;
    activityVC.excludedActivityTypes = @[UIActivityTypeAirDrop, UIActivityTypePrint, UIActivityTypeAssignToContact,UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr, UIActivityTypePostToVimeo];
	
	[activityVC setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError)
	{
		if(activityType == UIActivityTypeSaveToCameraRoll)
		{
			[self showToast:2];
		}
	}];

    [self presentViewController:activityVC animated:YES completion:nil];
}

-(void)photoEditorCanceled:(AdobeUXImageEditorViewController *)editor
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
