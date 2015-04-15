//
//  Macro.h
//  DLNA_iOS
//
//  Created by ennrd on 4/15/15.
//  Copyright (c) 2015 ws. All rights reserved.
//

#ifndef DLNA_iOS_Macro_h
#define DLNA_iOS_Macro_h


#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject; \


#define NotificationFlag_StatusChanged @"Changed"
#endif
