//
//  ActionViewController.m
//  Live Photo Frame Picker Action
//
//  Created by Marwan Harb on 10/3/17.
//  Copyright © 2017 Apps & Games. All rights reserved.
//

#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "ActionUtils.h"
#import "ActionFramePickerVCCell.h"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))

@import Photos;
@import PhotosUI;
@import UIGifImage;
@import NSGIF;

@interface ActionViewController ()
{
    PHAsset* lpAsset;
    BOOL gifComplete;
    NSURL* gifURL;
    NSInteger state;
    NSMutableArray* imageArray;
    
    CIContext* cicontext;
}

@property(copy) PHLivePhotoFrameProcessingBlock frameProcessor;

@end

@implementation ActionViewController

-(void)viewWillAppear:(BOOL)animated
{
    lpFound = NO;
    processed = NO;
    parsingComplete = NO;
//    _loading.hidden = YES;
    state = 1;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    for (NSExtensionItem *item in self.extensionContext.inputItems)
    {
        for (NSItemProvider *itemProvider in item.attachments)
        {
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeLivePhoto])
            {
                [self initView];
                
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(NSURL *image, NSError *error)
                {
                    NSString *JPEGfilename = [image lastPathComponent];
                    NSString* fileName = [JPEGfilename componentsSeparatedByString:@"."][0];
                    
                    PHFetchResult* assets = [PHAsset fetchAssetsWithOptions:nil];
                    for (NSInteger i = 0; i < assets.count; i++)
                    {
                        if(lpFound == NO)
                        {
                            PHAsset* as = assets[i];
                            
                            PHImageRequestOptions * imageRequestOptions = [[PHImageRequestOptions alloc] init];
                            imageRequestOptions.synchronous = YES;
                            [[PHImageManager defaultManager] requestImageDataForAsset:as options:imageRequestOptions resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info){
                                if ([info objectForKey:@"PHImageFileURLKey"])
                                {
                                    NSURL *path = [info objectForKey:@"PHImageFileURLKey"];

                                    if ([[NSString stringWithFormat:@"%@",path] rangeOfString:fileName].location != NSNotFound && [[NSString stringWithFormat:@"%@",path] rangeOfString:@"DCIM"].location != NSNotFound)
                                    {
                                        [[PHImageManager defaultManager] requestLivePhotoForAsset:as targetSize:CGSizeMake(256, 256) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
                                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                _loading.hidden = YES;
                                            }];
                                            [self imgFound:livePhoto withAsset:as];
                                            lpFound = YES;
                                        }];
                                    }
                                }
                                else
                                {
                                    NSLog(@"Image not found");
                                }
                            }];
                        }
                        else
                        {
                            break;
                        }
                    }
                }];
            }
            else
            {
                _lblNotLivePhoto.hidden = NO;
                _vLivePhotoContainer.hidden = YES;
                _vToolbar.hidden = YES;
                _vFrameContainer.hidden = YES;
                _vCreatingGif.hidden = YES;
                _vToast.hidden = YES;
                _ivSeparator.hidden = YES;
                _lblExportAs.hidden = YES;
            }
        }
    }
}

-(void) initView
{
    _btnLeftNavbar.title = @"Done";
    state = 1;
    _lblNotLivePhoto.hidden = YES;
    _vFrameContainer.hidden = YES;
    
    _btnGifOutlet.backgroundColor = [ActionUtils colorFromHexString:@COLOUR_PREVIEW_VC_TOOLBAR_BG];
    [_btnGifOutlet setTitleColor:[ActionUtils colorFromHexString:@COLOUR_PREVIEW_VC_TOOLBAR_TEXT] forState:UIControlStateNormal];
    _btnGifOutlet.layer.cornerRadius = 5;
    
    _btnMovOutlet.backgroundColor = [ActionUtils colorFromHexString:@COLOUR_PREVIEW_VC_TOOLBAR_BUTTON_BG];
    [_btnMovOutlet setTitleColor:[ActionUtils colorFromHexString:@COLOUR_PREVIEW_VC_TOOLBAR_TEXT] forState:UIControlStateNormal];
    _btnMovOutlet.layer.cornerRadius = 5;
    
//    _btnFrameOutlet.backgroundColor = [ActionUtils colorFromHexString:@COLOUR_PREVIEW_VC_TOOLBAR_BUTTON_BG];
    _btnFrameOutlet.backgroundColor = [ActionUtils colorFromHexString:@"#555555"];
    [_btnFrameOutlet setTitleColor:[ActionUtils colorFromHexString:@COLOUR_PREVIEW_VC_TOOLBAR_TEXT] forState:UIControlStateNormal];
    _btnFrameOutlet.layer.cornerRadius = 5;
    _btnFrameOutlet.enabled = NO;
    
    [_btnExportFrame setTitleColor:[ActionUtils colorFromHexString:@COLOUR_FRAME_PICKER_VC_TOOLBAR_BUTTON_TEXT] forState:UIControlStateNormal];
    _btnExportFrame.backgroundColor = [ActionUtils colorFromHexString:@COLOUR_FRAME_PICKER_VC_TOOLBAR_BUTTON_BG];
    _btnExportFrame.layer.cornerRadius = 5;
    
    _lblExportAs.textColor = [ActionUtils colorFromHexString:@COLOUR_PREVIEW_VC_TEXT];
    
    _vCreatingGif.hidden = YES;
    gifComplete = NO;
    
    _vToast.layer.cornerRadius = 20;
    _vToast.alpha = 0.6;
    _vToast.hidden = YES;
}

-(void) imgFound:(PHLivePhoto*) lp withAsset:(PHAsset*) asset
{
    _vLivePhoto.livePhoto = lp;
    lpAsset = asset;
    
    if(lpFound)
    {
        [self initGif];
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        dispatch_async(queue, ^{
            [self getFramesFromVid];
            dispatch_sync(dispatch_get_main_queue(), ^{
                
            });
        });
    
        _ivBadge.image = [PHLivePhotoView livePhotoBadgeImageWithOptions:PHLivePhotoBadgeOptionsOverContent];
    }
}

-(void) initGif
{
    PHAssetResource* phAR = [[PHAssetResource assetResourcesForAsset:lpAsset] lastObject];
    
    NSString* path = NSTemporaryDirectory();
    NSString* finalPath = [path stringByAppendingPathComponent:@"temp.mov"];
    
    [ActionUtils emptyTempDirectory];
    
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

-(void) getFramesFromVid
{
    PHAssetResource* phAR = [[PHAssetResource assetResourcesForAsset:lpAsset] lastObject];
    
    NSString* path = NSTemporaryDirectory();
    NSString* finalPath = [path stringByAppendingPathComponent:@"lp_mov.mov"];
    NSString* framesPath = [path stringByAppendingPathComponent:@"/frames/"];
    NSURL* framesURL = [NSURL fileURLWithPath:framesPath];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:framesPath])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:framesPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    [ActionUtils removeTempFilePath:finalPath];
    
    [[PHAssetResourceManager defaultManager] writeDataForAssetResource:phAR toFile:[NSURL fileURLWithPath:finalPath] options:nil completionHandler:^(NSError * _Nullable error)
     {
         AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:finalPath] options:nil];
         AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
         generator.requestedTimeToleranceAfter =  kCMTimeZero;
         generator.requestedTimeToleranceBefore =  kCMTimeZero;
         CMTime time;
         NSError *err;
         CMTime actualTime;
         CGImageRef image;
         UIImage *generatedImage;
         NSURL* fileURL;
         NSData* jpgData;
         AVAssetTrack* track = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
         NSInteger FPS = track.nominalFrameRate;
//         UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
         CGAffineTransform txf = [track preferredTransform];
         CGFloat videoAngleInDegrees = RADIANS_TO_DEGREES(atan2(txf.b, txf.a));
         
         for (Float64 i = 0; i < CMTimeGetSeconds(asset.duration) *  FPS ; i++)
         {
             @autoreleasepool
             {
                 time = CMTimeMake(i, FPS);
                 image = [generator copyCGImageAtTime:time actualTime:&actualTime error:&err];
                 generatedImage = [[UIImage alloc] initWithCGImage:image];
                 
                 switch ((int)videoAngleInDegrees)
                 {
                     case 0:
                         generatedImage = [UIImage imageWithCGImage:generatedImage.CGImage scale:1.0 orientation:UIImageOrientationUp];
                         break;
                         
                     case 90:
                         generatedImage = [UIImage imageWithCGImage:generatedImage.CGImage scale:1.0 orientation:UIImageOrientationRight];
                         break;
                         
                     case 180:
                         generatedImage = [UIImage imageWithCGImage:generatedImage.CGImage scale:1.0 orientation:UIImageOrientationDown];
                         break;
                         
                     case -90:
                         generatedImage = [UIImage imageWithCGImage:generatedImage.CGImage scale:1.0 orientation:UIImageOrientationLeft];
                         break;
                         
                     default:
                         break;
                 }
                 
                 fileURL = [[framesURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%d", (int)i]] URLByAppendingPathExtension:@"jpg"];
                 jpgData = UIImageJPEGRepresentation(generatedImage, 0.5);
                 [jpgData writeToFile:[fileURL path] atomically:YES];
                 CGImageRelease(image);
             }
         }
         
         dispatch_async(dispatch_get_main_queue(), ^{
             _btnFrameOutlet.backgroundColor = [ActionUtils colorFromHexString:@COLOUR_PREVIEW_VC_TOOLBAR_BUTTON_BG];
             [_btnFrameOutlet setTitleColor:[ActionUtils colorFromHexString:@COLOUR_PREVIEW_VC_TOOLBAR_TEXT] forState:UIControlStateNormal];
             _btnFrameOutlet.layer.cornerRadius = 5;
             _btnFrameOutlet.enabled = YES;
             
             parsingComplete = YES;
//             NSLog(@"Parsing complete");
         });
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
        PHAssetResource* phAR = [[PHAssetResource assetResourcesForAsset:lpAsset] lastObject];
        
        NSString* path = NSTemporaryDirectory();
        NSString* finalPath = [path stringByAppendingPathComponent:@"temp.mov"];
        
        [ActionUtils emptyTempDirectory];
        
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
    PHAssetResource* phAR = [[PHAssetResource assetResourcesForAsset:lpAsset] lastObject];
    
    NSString* path = NSTemporaryDirectory();
    NSString* finalPath = [path stringByAppendingPathComponent:@"temp.mov"];
    
    [ActionUtils removeTempFilePath:finalPath];
    
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

-(void) showToast:(NSInteger)seconds
{
    [UIView transitionWithView:_vToast duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{_vToast.hidden = NO; _vToast.alpha = 1;}completion:NULL];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [UIView transitionWithView:_vToast duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{_vToast.alpha = 0;}completion:^(BOOL finished) {
            _vToast.hidden = YES;
        }];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)done
{
    if(state == 1)
    {
        [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
    }
    else
    {
        _btnLeftNavbar.title = @"Done";
        state = 1;
        _vLivePhotoContainer.hidden = NO;
        _vToolbar.hidden = NO;
        _lblExportAs.hidden = NO;
        _ivSeparator.hidden = NO;
        _vFrameContainer.hidden = YES;
    }
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
    _btnLeftNavbar.title = @"Back";
    state = 2;
    _vLivePhotoContainer.hidden = YES;
    _vToolbar.hidden = YES;
    _lblExportAs.hidden = YES;
    _ivSeparator.hidden = YES;
    _loading.hidden = NO;
    
//    cicontext = [CIContext contextWithOptions:nil];
    
//    if(processed == NO)
//    {
//        [lpAsset requestContentEditingInputWithOptions:nil completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
//            [self processLivePhoto:contentEditingInput];
//        }];
//    }
    
    if(parsingComplete)
    {
        [self getFrames];
    }
}

-(void) getFrames
{
    imageArray = [NSMutableArray array];
    NSString* framesPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/frames/"];
    NSArray* framesDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:framesPath error:nil];
    NSArray *sortedArray = [framesDirectory sortedArrayUsingComparator:^(id str1, id str2)
    {
        return [((NSString *)str1) compare:((NSString *)str2) options:NSNumericSearch];
    }];
    
    for (NSString* file in sortedArray)
    {
        [imageArray addObject:[UIImage imageWithContentsOfFile:[framesPath stringByAppendingPathComponent:file]]];
    }
    
//    NSLog(@"count: %lu", imageArray.count);
    [_cvFramePicker reloadData];
    int pos = (int) imageArray.count / 2;
    NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:pos inSection:0];
    
    [_cvFramePicker scrollToItemAtIndexPath:pathToLastItem atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    _ivFrame.image = [imageArray objectAtIndex:pos];
    _ivFrame.tag = pos;
    _ivFrameIndicator.alpha = 1;
    
    _vFrameContainer.hidden = NO;
    _loading.hidden = YES;
    processed = YES;
}

//- (void)processLivePhoto:(PHContentEditingInput *)input
//{
//    imageArray = [[NSMutableArray alloc]init];
//
//    __block NSInteger hello = 0;
//    NSMutableArray<CIImage*>* test = [NSMutableArray array];
//    PHLivePhotoEditingContext *context = [[PHLivePhotoEditingContext alloc] initWithLivePhotoEditingInput:input];
//    context.frameProcessor = ^CIImage *(id <PHLivePhotoFrame> frame, NSError **error)
//    {
//        [imageArray addObject:[self makeUIImageFromCIImage:frame.image shouldScale:YES]];
//
////        [imageArray addObject:[UIImage imageNamed:@"bg_gradient"]];
//
////        if(hello % 2 == 0)
////        {
////            NSLog(@"kajsdhaksjdh");
////        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
////        dispatch_async(queue, ^{
////            [test addObject:frame.image];
//////            dispatch_sync(dispatch_get_main_queue(), ^{
//////                // Update UI
//////                // Example:
//////                // self.myLabel.text = result;
//////            });
////        });
//
////        }
//
//        NSLog(@"count: %lu", hello);
//        hello ++;
//        return frame.image;
//    };
//
//    PHContentEditingOutput *output = [[PHContentEditingOutput alloc] initWithContentEditingInput: input];
//    [context saveLivePhotoToOutput:output options:nil completionHandler:^(BOOL success, NSError * _Nullable error)
//     {
//         if(success)
//         {
//             NSLog(@"skjhdakjshdkasjhdas");
////             for (CIImage* ciImage in test)
////             {
////                 NSLog(@"sharmouta");
//////                 [imageArray addObject:[self makeUIImageFromCIImage:ciImage shouldScale:YES]];
////             }
//
//
//             //TO UNCOMMENT
//             [imageArray removeObjectAtIndex:0];
//             [_cvFramePicker reloadData];
//
//             int pos = (int) imageArray.count / 2;
//             NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:pos inSection:0];
//
//             [_cvFramePicker scrollToItemAtIndexPath:pathToLastItem atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
//             _ivFrame.image = [imageArray objectAtIndex:pos];
//             _ivFrame.tag = pos;
//             _ivFrameIndicator.alpha = 1;
//
//             _vFrameContainer.hidden = NO;
//             _loading.hidden = YES;
//             processed = YES;
//         }
//         else
//         {
//             UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ERROR", @"Error") message:NSLocalizedString(@"ERROR_PARSING_LIVE_PHOTO", @"Error parsing livephoto") preferredStyle:UIAlertControllerStyleAlert];
//             UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
//                 [self.navigationController popViewControllerAnimated:YES];
//             }];
//
//             [alert addAction:defaultAction];
//             [self presentViewController:alert animated:YES completion:nil];
//         }
//     }];
//}

//-(UIImage*)makeUIImageFromCIImage:(CIImage*)ciImage shouldScale:(BOOL) scale
//{
//    UIImage * returnImage;
//    returnImage = [UIImage imageWithCGImage:[cicontext createCGImage:ciImage fromRect:[ciImage extent]]];
//
//    if(scale == YES)
//    {
//        returnImage = [self imageWithImage:returnImage scaledToFillSize:CGSizeMake(_ivFrame.frame.size.width, _ivFrame.frame.size.height)];
//    }
//
//    NSLog(@"RET: %@", ciImage);
//
//    return returnImage;
//}

//- (UIImage *)imageWithImage:(UIImage *)image scaledToFillSize:(CGSize)size
//{
//    CGFloat scale = MAX(size.width/image.size.width, size.height/image.size.height);
//    CGFloat width = image.size.width * scale;
//    CGFloat height = image.size.height * scale;
//    CGRect imageRect = CGRectMake((size.width - width)/2.0f,
//                                  (size.height - height)/2.0f,
//                                  width,
//                                  height);
//
//    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
//    [image drawInRect:imageRect];
//    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return newImage;
//}

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
    ActionFramePickerVCCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"frameCell" forIndexPath:indexPath];
    
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
        _ivFrame.tag = ip.row;
    }
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, ((_cvFramePicker.frame.size.width / 2) - (_cvFramePicker.frame.size.height / 2)), 0, ((_cvFramePicker.frame.size.width / 2) - (_cvFramePicker.frame.size.height / 2)));
}

- (IBAction)btnExport:(id)sender
{
    NSData *compressedImage = UIImageJPEGRepresentation(_ivFrame.image, 0.8 );
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[compressedImage ] applicationActivities:nil];
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
@end
