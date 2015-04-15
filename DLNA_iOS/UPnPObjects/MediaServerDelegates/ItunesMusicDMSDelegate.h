//
//  ItunesMusicDMSDelegate.h
//  DLNA_iOS
//
//  Created by wangshuaidavid on 12-8-21.
//
//

#import <UIKit/UIKit.h>
#import <Platinum/Platinum.h>
#import "PltMediaServerObject.h"

@interface ItunesMusicDMSDelegate : NSObject <PLT_MediaServerDelegateObject> {
	
}

@property(nonatomic, retain)NSArray *albumsArray;

@end
