//
//  LivePhotoModel.m
//  Live Photo Frame Picker
//
//  Created by Marwan Harb on 10/3/17.
//  Copyright © 2017 Apps & Games. All rights reserved.
//

#import "LivePhotoModel.h"

@implementation LivePhotoModel

-(id) initWithAlbumName:(NSString*) albumName andAssetId:(NSString*) assetId
{
    self = [super init];
    
    if(self != nil)
    {
        _albumName = albumName;
        _assetId = assetId;
    }
    
    return self;
}

-(NSString*) getAlbumName
{
    return _albumName;
}

-(void) setAlbumName:(NSString *)albumName
{
    _albumName = albumName;
}

-(NSString*) getAssetId
{
    return _assetId;
}

-(void) setAssetId:(NSString *)assetId
{
    _assetId = assetId;
}

@end
