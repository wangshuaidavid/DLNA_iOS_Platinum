//
//  Util.m
//  DongleSystem
//
//  Created by wangshuaidavid on 12-5-31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#include <ifaddrs.h>
#include <arpa/inet.h>

#import "Macro.h"
#import "Util.h"

NSString *const UTIL_DATE_FORMAT_PATTERN = @"yyyy-MM-dd hh:mm aa";

@implementation Util

+ (id)sharedInstance
{
  DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
    return [[self alloc] init];
  });
}

#pragma mark - DocumentPath
- (NSString *)getDocumentPath {
	NSString *userDocumentsPath = nil;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0) {
    userDocumentsPath = [paths objectAtIndex:0];
	}
	return userDocumentsPath;
}


- (UIColor *)getTableCellTextColor {
	return [UIColor colorWithRed:0/255.0	green:64/255.0 blue:128/255.0 alpha:1.0];
}


- (NSString *)uppercaseFirstLetter:(NSString *)inputString {
	NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en-US"];
	NSString *firstChar = [inputString substringToIndex:1];
	NSString *folded = [firstChar stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:locale];
	NSString *result = [[folded uppercaseString] stringByAppendingString:[inputString substringFromIndex:1]];
	return result;
}


- (NSString *)getIPAddress
{
  NSString *address = @"error";
  struct ifaddrs *interfaces = NULL;
  struct ifaddrs *temp_addr = NULL;
  int success = 0;
	
  // retrieve the current interfaces - returns 0 on success
  success = getifaddrs(&interfaces);
  if (success == 0)
  {
    // Loop through linked list of interfaces
    temp_addr = interfaces;
    while(temp_addr != NULL)
    {
      if(temp_addr->ifa_addr->sa_family == AF_INET)
      {
        // Check if interface is en0 which is the wifi connection on the iPhone
        if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
        {
          // Get NSString from C String
          address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
        }
      }
			
      temp_addr = temp_addr->ifa_next;
    }
  }
	
  // Free memory
  freeifaddrs(interfaces);
	
  return address;
}


- (BOOL)isStringAvalible:(NSString *)aStringValue {
	BOOL retBool = NO;
	NSString *trimedStringValue = [aStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (trimedStringValue && ![trimedStringValue isEqualToString:@""]) {
		retBool = YES;
	}
	return retBool;
}


- (NSString *)formateDate: (NSDate *)date {
	if (!formatter) {
		formatter = [[NSDateFormatter alloc] init];		
		[formatter setDateFormat:UTIL_DATE_FORMAT_PATTERN];		
	}
	return [formatter stringFromDate:date];
}



@end
