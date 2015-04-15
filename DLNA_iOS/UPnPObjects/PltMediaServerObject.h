//
//  PltMediaServerObject.h
//  Platinum
//
//  Created by Sylvain on 9/14/10.
//  Modified by WS 2012/8
//  Copyright 2010 Plutinosoft LLC. All rights reserved.
//

#include <UIKit/UIKit.h>
#import <Platinum/Platinum.h>
#import <Platinum/PltUPnPObject.h>

//#import "PltUPnPObject.h"

// define 
#if !defined(_PLATINUM_H_)
typedef class PLT_HttpRequestContext PLT_HttpRequestContext;
typedef class NPT_HttpResponse NPT_HttpResponse;
#endif

/*----------------------------------------------------------------------
|   PLT_MediaServerObject
+---------------------------------------------------------------------*/
@interface PLT_MediaServerObject : PLT_DeviceHostObject {}

@property (nonatomic, weak) id delegate; // we do not retain to avoid circular ref count

- (id)initServerWithPath:(NSString *)thePath andServerName:(NSString *)theServerName;
- (id)initServerSelfDelegateWithServerName:(NSString *)theServerName ;

@end

/*----------------------------------------------------------------------
|   PLT_MediaServerBrowseCapsule
+---------------------------------------------------------------------*/
@interface PLT_MediaServerBrowseCapsule : PLT_ActionObject {
    NPT_UInt32              start;
    NPT_UInt32              count;
    PLT_HttpRequestContext* context;
}

- (id)initWithAction:(PLT_Action*)action objectId:(const char*)objectId filter:(const char*)filter start:(NPT_UInt32)start count:(NPT_UInt32)count sort:(const char*)sort context:(PLT_HttpRequestContext*)context;


- (PLT_HttpRequestContext *)getContext ;

@property (readonly, strong) NSString* objectId;
@property (readonly) NPT_UInt32 start;
@property (readonly) NPT_UInt32 count;
@property (readonly, strong) NSString* filter;
@property (readonly, strong) NSString* sort;
@end

/*----------------------------------------------------------------------
|   PLT_MediaServerSearchCapsule
+---------------------------------------------------------------------*/
@interface PLT_MediaServerSearchCapsule : PLT_MediaServerBrowseCapsule {}

- (id)initWithAction:(PLT_Action*)action objectId:(const char*)objectId search:(const char*)search filter:(const char*)filter start:(NPT_UInt32)start count:(NPT_UInt32)count sort:(const char*)sort context:(PLT_HttpRequestContext*)context;

@property (readonly, strong) NSString* search;
@end

/*----------------------------------------------------------------------
|   PLT_MediaServerFileRequestCapsule
+---------------------------------------------------------------------*/
@interface PLT_MediaServerFileRequestCapsule : NSObject {
    NPT_HttpResponse*       response;
    PLT_HttpRequestContext* context;
}

- (id)initWithResponse:(NPT_HttpResponse*)response context:(PLT_HttpRequestContext*)context;

- (NPT_HttpResponse *)getResponse;
- (PLT_HttpRequestContext *)getContext;

@end

/*----------------------------------------------------------------------
|   PLT_MediaServerDelegateObject
+---------------------------------------------------------------------*/
@protocol PLT_MediaServerDelegateObject
- (NPT_Result)onBrowseMetadata:(PLT_MediaServerBrowseCapsule*)info;
- (NPT_Result)onBrowseDirectChildren:(PLT_MediaServerBrowseCapsule*)info;
- (NPT_Result)onSearchContainer:(PLT_MediaServerSearchCapsule*)info;
- (NPT_Result)onFileRequest:(PLT_MediaServerFileRequestCapsule*)info withURL:(NSString *)theURL;

//- (NPT_Result)onFileRequest:(PLT_MediaServerFileRequestCapsule*)info;
@end
