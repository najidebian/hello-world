//
//  PreviewVC.m
//  Live Photo Frame Picker
//
//  Created by Marwan Harb on 6/8/17.
//  Copyright © 2017 Apps & Games. All rights reserved.
//

#import "PreviewVC.h"
#import "Utils.h"
#import "FramePickerVC.h"

@import Photos;
@import PhotosUI;
@import UIGifImage;
@import NSGIF;

@interface PreviewVC ()
{
    PHAsset* asset;
    BOOL gifComplete;
    NSURL* gifURL;
}

@property(copy) PHLivePhotoFrameProcessingBlock frameProcessor;

@end

@implementation PreviewVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    NSLog(@"ksjfdklsdksdhfkjsjksdhfksjh");
//    [self.navigationController popViewControllerAnimated:YES];
		
    [self initVars];
}

-(void) initVars
{
    self.view.backgroundColor = [Utils colorFromHexString:@COLOUR_PREVIEW_VC_BG];
	
	_btnGifOutlet.backgroundColor = [Utils colorFromHexString:@COLOUR_PREVIEW_VC_TOOLBAR_BUTTON_BG];
	[_btnGifOutlet setTitleColor:[Utils colorFromHexString:@COLOUR_PREVIEW_VC_TOOLBAR_TEXT] forState:UIControlStateNormal];
	_btnGifOutlet.layer.cornerRadius = 5;
	
	_btnMovOutlet.backgroundColor = [Utils colorFromHexString:@COLOUR_PREVIEW_VC_TOOLBAR_BUTTON_BG];
	[_btnMovOutlet setTitleColor:[Utils colorFromHexString:@COLOUR_PREVIEW_VC_TOOLBAR_TEXT] forState:UIControlStateNormal];
	_btnMovOutlet.layer.cornerRadius = 5;
	
	_btnFrameOutlet.backgroundColor = [Utils colorFromHexString:@COLOUR_PREVIEW_VC_TOOLBAR_BUTTON_BG];
	[_btnFrameOutlet setTitleColor:[Utils colorFromHexString:@COLOUR_PREVIEW_VC_TOOLBAR_TEXT] forState:UIControlStateNormal];
	_btnFrameOutlet.layer.cornerRadius = 5;
	
	_lblExportAs.textColor = [Utils colorFromHexString:@COLOUR_PREVIEW_VC_TEXT];
	
	_vToast.layer.cornerRadius = 20;
	_vToast.alpha = 0.6;
	_vToast.hidden = YES;
    
    asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[_assetID] options:nil] firstObject];

    [[PHImageManager defaultManager] requestLivePhotoForAsset:asset targetSize:self.view.frame.size contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info)
     {
         _lpvPreview.livePhoto = livePhoto;
         
         if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
         {
             _ivBadge.frame = CGRectMake(0, _lpvPreview.frame.origin.y, self.view.frame.size.width / 20, self.view.frame.size.width / 20);
         }
         else
         {
             _ivBadge.frame = CGRectMake(0, _lpvPreview.frame.origin.y, self.view.frame.size.width / 8, self.view.frame.size.width / 8);
         }
         _ivBadge.image = [PHLivePhotoView livePhotoBadgeImageWithOptions:PHLivePhotoBadgeOptionsOverContent];
     }];
    
     _vCreatingGif.hidden = YES;
     gifComplete = NO;
     [self initGif];
}

-(void) showToast:(NSInteger)seconds
{
	[UIView transitionWithView:_vToast duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{_vToast.hidden = NO; _vToast.alpha = 1;}completion:NULL];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[UIView transitionWithView:_vToast duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{_vToast.alpha = 0;}completion:^(BOOL finished) {
			_vToast.hidden = YES;
		}];
	});
}

-(void) initGif
{
    PHAssetResource* phAR = [[PHAssetResource assetResourcesForAsset:asset] lastObject];
    
    NSString* path = NSTemporaryDirectory();
    NSString* finalPath = [path stringByAppendingPathComponent:@"temp.mov"];
    
    [Utils emptyTempDirectory];
    
    [[PHAssetResourceManager defaultManager] writeDataForAssetResource:phAR toFile:[NSURL fileURLWithPath:finalPath] options:nil completionHandler:^(NSError * _Nullable error)
     {
         if(error == NULL)
         {
//             _vCreatingGif.hidden = NO;
             [NSGIF createGIFfromURL:[NSURL fileURLWithPath:finalPath] withFrameCount:30 delayTime:.10 loopCount:0 completion:^(NSURL *GifURL)
              {
                  if(GifURL.absoluteString.length == 0)
                  {
                      gifComplete = NO;
                      
                      UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ERROR", @"Error") message:NSLocalizedString(@"ERROR_PARSING_LIVE_PHOTO", @"Error parsing livephoto") preferredStyle:UIAlertControllerStyleAlert];
                      UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                      
                      [alert addAction:defaultAction];
                      [self presentViewController:alert animated:YES completion:nil];
                  }
                  else
                  {
                      gifComplete = YES;
                      gifURL = GifURL;
                  }
              }];
         }
         else
         {
             UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ERROR", @"Error") message:NSLocalizedString(@"ERROR_PARSING_LIVE_PHOTO", @"Error parsing livephoto") preferredStyle:UIAlertControllerStyleAlert];
             UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
             
             [alert addAction:defaultAction];
             [self presentViewController:alert animated:YES completion:nil];
         }
     }];
}

-(void) getGifFromLivePhotoAsset
{
    if(gifComplete)
    {
        NSData* gifData = [NSData dataWithContentsOfURL:gifURL];
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[gifData] applicationActivities:nil];
        activityVC.popoverPresentationController.sourceView = _vToolbar;
		activityVC.popoverPresentationController.sourceRect = _vToolbar.bounds;
		
		[activityVC setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError)
		 {
			 if(activityType == UIActivityTypeSaveToCameraRoll)
			 {
				 [self showToast:2];
			 }
		 }];
		 
        [self presentViewController:activityVC animated:YES completion:nil];
    }
    else
    {
        PHAssetResource* phAR = [[PHAssetResource assetResourcesForAsset:asset] lastObject];
        
        NSString* path = NSTemporaryDirectory();
        NSString* finalPath = [path stringByAppendingPathComponent:@"temp.mov"];
        
        [Utils emptyTempDirectory];
        
        [[PHAssetResourceManager defaultManager] writeDataForAssetResource:phAR toFile:[NSURL fileURLWithPath:finalPath] options:nil completionHandler:^(NSError * _Nullable error)
         {
             if(error == NULL)
             {
                 _vCreatingGif.hidden = NO;
                 [NSGIF createGIFfromURL:[NSURL fileURLWithPath:finalPath] withFrameCount:30 delayTime:.10 loopCount:0 completion:^(NSURL *GifURL)
                  {
                      _vCreatingGif.hidden = YES;
                      if(GifURL.absoluteString.length == 0)
                      {
                          UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ERROR", @"Error") message:NSLocalizedString(@"ERROR_CREATING_GIF", @"Error creating gif") preferredStyle:UIAlertControllerStyleAlert];
                          UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                          
                          [alert addAction:defaultAction];
                          [self presentViewController:alert animated:YES completion:nil];
                      }
                      else
                      {
                          gifURL = GifURL;
                          NSData* gifData = [NSData dataWithContentsOfURL:gifURL];
                          UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[gifData] applicationActivities:nil];
                          activityVC.popoverPresentationController.sourceView = _vToolbar;
                          activityVC.popoverPresentationController.sourceRect = _vToolbar.bounds;
						  
						  [activityVC setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError)
						   {
							   if(activityType == UIActivityTypeSaveToCameraRoll)
							   {
								   [self showToast:2];
							   }
						   }];
						  
                          [self presentViewController:activityVC animated:YES completion:nil];
                          
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
}

-(void) getVidFromLivePhotoAsset
{
    PHAssetResource* phAR = [[PHAssetResource assetResourcesForAsset:asset] lastObject];
    
    NSString* path = NSTemporaryDirectory();
    NSString* finalPath = [path stringByAppendingPathComponent:@"temp.mov"];
    
    [Utils removeTempFilePath:finalPath];
    
    [[PHAssetResourceManager defaultManager] writeDataForAssetResource:phAR toFile:[NSURL fileURLWithPath:finalPath] options:nil completionHandler:^(NSError * _Nullable error)
     {
         UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects:[NSURL fileURLWithPath:finalPath], nil] applicationActivities:nil];
         activityVC.popoverPresentationController.sourceView = _vToolbar;
		 activityVC.popoverPresentationController.sourceRect = _vToolbar.bounds;
		 
		 [activityVC setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError)
		  {
			  if(activityType == UIActivityTypeSaveToCameraRoll)
			  {
				  [self showToast:2];
			  }
		  }];
		 
         [self presentViewController:activityVC animated:YES completion:nil];
     }];
}

-(void) video:(NSString*)videoPath didfinishSavingWithError:(NSError*)error contextInfo:(void*)ctx
{
    UIAlertController* alert;
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    
    if(error == NULL)
    {
        alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"SUCCESS", @"Success") message:NSLocalizedString(@"VIDEO_SAVED_SUCCESSFULLY", @"Video saved successfully") preferredStyle:UIAlertControllerStyleAlert];
    }
    else
    {
        alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ERROR", @"Error") message:NSLocalizedString(@"ERROR_SAVING_VIDEO", @"Error saving video") preferredStyle:UIAlertControllerStyleAlert];
    }
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)btnGif:(id)sender
{
    [self getGifFromLivePhotoAsset];
}

- (IBAction)btnMov:(id)sender
{
    [self getVidFromLivePhotoAsset];
}

- (IBAction)btnFrame:(id)sender
{
    [self performSegueWithIdentifier:@"previewToFramePicker" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier  isEqual: @"previewToFramePicker"])
    {
        FramePickerVC* vc = segue.destinationViewController;
        vc.assetID = _assetID;
    }
}

@end
