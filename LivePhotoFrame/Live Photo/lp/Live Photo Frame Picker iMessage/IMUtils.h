//
//  IMUtils.h
//  Live Photo Frame Picker
//
//  Created by Marwan Harb on 6/14/17.
//  Copyright © 2017 Apps & Games. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IMUtils : NSObject

+(UIColor *) colorFromHexString:(NSString *)hexString;
+(void)removeTempFilePath:(NSString*)filePath;
+ (void)emptyTempDirectory;

@end
