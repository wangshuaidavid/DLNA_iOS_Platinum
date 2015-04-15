//
//  PhotoDMSDelegate.h
//  DLNA_iOS
//
//  Created by wangshuaidavid on 12-8-14.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PltMediaServerObject.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface PhotoDMSDelegate : NSObject <PLT_MediaServerDelegateObject>{
	
	NSMutableArray *assetGroups;
	NSMutableDictionary *typeDictionary;
}

+ (ALAssetsLibrary *)defaultAssetsLibrary;
- (NSDictionary *)getTypeDictionary ;

@end
