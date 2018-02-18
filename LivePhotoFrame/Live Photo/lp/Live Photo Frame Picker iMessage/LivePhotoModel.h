//
//  LivePhotoModel.h
//  Live Photo Frame Picker
//
//  Created by Marwan Harb on 10/3/17.
//  Copyright © 2017 Apps & Games. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LivePhotoModel : NSObject

@property (nonatomic, strong) NSString* albumName;
@property (nonatomic, strong) NSString* assetId;

-(id) initWithAlbumName:(NSString*) albumName andAssetId:(NSString*) assetId;
-(NSString*) getAlbumName;
-(void) setAlbumName:(NSString *)albumName;
-(void) setAssetId:(NSString *)assetId;
-(NSString*) getAssetId;

@end
