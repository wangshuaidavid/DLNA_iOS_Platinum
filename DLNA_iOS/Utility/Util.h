//
//  Util.h
//  DongleSystem
//
//  Created by wangshuaidavid on 12-5-31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Util : NSObject {
	
	NSDateFormatter *formatter;
}
	
- (NSString *)getDocumentPath ;
- (UIColor *)getTableCellTextColor;
- (NSString *)uppercaseFirstLetter:(NSString *)inputString ;
- (NSString *)getIPAddress;
- (BOOL)isStringAvalible:(NSString *)aStringValue ;

- (NSString *)formateDate: (NSDate *)date ;

+ (id)sharedInstance;

@end
