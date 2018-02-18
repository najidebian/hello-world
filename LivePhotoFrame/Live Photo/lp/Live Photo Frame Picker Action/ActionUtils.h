//
//  Utils.h
//  AGLoginFramework
//
//  Created by Marwan Harb on 5/15/17.
//  Copyright © 2017 NM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ActionUtils : NSObject

+(UIColor *) colorFromHexString:(NSString *)hexString;
+(void)removeTempFilePath:(NSString*)filePath;
+ (void)emptyTempDirectory;
+ (void) listTempDirectory;

@end
