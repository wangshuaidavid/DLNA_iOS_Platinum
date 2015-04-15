//
//  UPnPEngine.h
//  DLNA_iOS
//
//  Created by wang david on 12-9-12.
//
//


#import "PhotoDMSDelegate.h"
#import "ItunesMusicDMSDelegate.h"

#import <Foundation/Foundation.h>

@interface UPnPEngine : NSObject {
  
  PLT_UPnPObject* upnp;
  
  PLT_MediaServerObject* localFileServer;
	PLT_MediaServerObject* itunesServer;
	PLT_MediaServerObject* photoServer;
  
  PhotoDMSDelegate *photoDMSDelegate;
	ItunesMusicDMSDelegate *itunesDMSDelegate;
}

+ (id)getEngine;

- (void)intendStartLocalFileServerWithRootPath:(NSString *)thePath serverName:(NSString *)theName;
- (void)intendStartItunesMusicServerWithServerName:(NSString *)theName;
- (void)intendStartIOSPhotoServerWithServerName:(NSString *)theName;

- (BOOL)startUPnP ;
- (void)stopUPnP ;

- (BOOL)isRunning;
@end
