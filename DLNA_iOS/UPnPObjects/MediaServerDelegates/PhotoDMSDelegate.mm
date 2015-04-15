//
//  PhotoDMSDelegate.m
//  DLNA_iOS
//
//  Created by wangshuaidavid on 12-8-14.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PhotoDMSDelegate.h"

#import "Util.h"

#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetExportSession.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AVFoundation/AVAssetTrack.h>

@implementation PhotoDMSDelegate

+ (ALAssetsLibrary *)defaultAssetsLibrary {
	static dispatch_once_t pred = 0;
	static ALAssetsLibrary *library = nil;
	dispatch_once(&pred, ^{
		library = [[ALAssetsLibrary alloc] init];
	});
	return library;
}

#pragma mark - DocumentPath
- (NSString *)getDocumentPath {
	return [[Util sharedInstance] getDocumentPath];
}

- (NSString *)getTempPath {
	return NSTemporaryDirectory();
}

- (NSDictionary *)getTypeDictionary {
	
	if (!typeDictionary) {
		typeDictionary = [[NSMutableDictionary alloc] initWithCapacity:100];
		[typeDictionary setObject:@"image/gif" forKey:@"gif"];
		[typeDictionary setObject:@"image/jpeg" forKey:@"thm"];
		[typeDictionary setObject:@"image/png" forKey:@"png"];
		[typeDictionary setObject:@"image/tiff" forKey:@"tif"];
		[typeDictionary setObject:@"image/tiff" forKey:@"tiff"];
		[typeDictionary setObject:@"image/jpeg" forKey:@"jpg"];
		[typeDictionary setObject:@"image/jpeg" forKey:@"jpeg"];
		[typeDictionary setObject:@"image/jpeg" forKey:@"jpe"];
		[typeDictionary setObject:@"image/jp2" forKey:@"jp2"];
		[typeDictionary setObject:@"image/bmp" forKey:@"bmp"];
		
		[typeDictionary setObject:@"video/mpeg" forKey:@"mpeg"];
		[typeDictionary setObject:@"video/mpeg" forKey:@"mpg"];
		[typeDictionary setObject:@"video/mp4" forKey:@"mp4"];
		[typeDictionary setObject:@"video/mp4" forKey:@"m4v"];
		[typeDictionary setObject:@"video/MP2T" forKey:@"ts"];
		[typeDictionary setObject:@"video/quicktime" forKey:@"mov"];
		[typeDictionary setObject:@"video/x-ms-wmv" forKey:@"wmv"];
		[typeDictionary setObject:@"video/x-ms-wmv" forKey:@"wtv"];
		[typeDictionary setObject:@"video/x-ms-asf" forKey:@"asf"];
		[typeDictionary setObject:@"video/x-msvideo" forKey:@"avi"];
		[typeDictionary setObject:@"video/x-msvideo" forKey:@"divx"];
		[typeDictionary setObject:@"video/x-msvideo" forKey:@"xvid"];

	}
	return typeDictionary;
}


- (BOOL)updateCurrentFileDate:(NSString *)theFilePath {
	
	BOOL retFlag = NO;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:theFilePath]) {
		NSDictionary *attributesDict = [NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate];
		NSError *error = nil;
		[[NSFileManager defaultManager] setAttributes:attributesDict ofItemAtPath:theFilePath error:&error];
		
		if (error) {
			NSLog(@"update date error!");
		}else {
			retFlag = YES;
		}
	}
	
	return retFlag;
}


NSInteger dateSortFunction(id s1, id s2, void *context) {
	
	NSDate *d1;
	[s1 getResourceValue:&d1 forKey:NSURLAttributeModificationDateKey error:NULL];
	NSDate *d2;
	[s2 getResourceValue:&d2 forKey:NSURLAttributeModificationDateKey error:NULL];
	
	return [d2 compare:d1];
}


- (void)sweepCache {
	
	static int cacheInt = 5;
	
	NSURL *url = [NSURL URLWithString:[self getTempPath]];
	//NSURL *url = [NSURL URLWithString:[self getDocumentPath]];
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtURL:url includingPropertiesForKeys:[NSArray arrayWithObject:NSURLContentModificationDateKey] options:NSDirectoryEnumerationSkipsSubdirectoryDescendants|NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsPackageDescendants errorHandler:nil];
	
	
	NSMutableArray *fileArray = [NSMutableArray arrayWithCapacity:15];
	
	for (NSURL *theFileURL in dirEnum) {
		
		NSString *fileName;
		[theFileURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
		
		if ([fileName rangeOfString:@"D_P_RES_"].location != NSNotFound) {
			[fileArray addObject:theFileURL];
		} 
		
	}
	
	if ([fileArray count] < cacheInt) {
		return;
	}
	
	NSArray* sortedArray = [fileArray sortedArrayUsingFunction:dateSortFunction context:nil];
	
	for (int i = cacheInt; i < [sortedArray count]; i ++) {
		NSError *deleteErr = nil;
		
		NSLog (@"delete %@", [sortedArray objectAtIndex:i]);
		
		[[NSFileManager defaultManager] removeItemAtURL:[sortedArray objectAtIndex:i] error:&deleteErr];
		if (deleteErr) {
			NSLog (@"Can't delete %@: %@", [sortedArray objectAtIndex:i], deleteErr);
		}
	}
}


- (const char*)getUPnPClass:(NSString *)mimeType {
	
	const char* ret = NULL;
	NPT_String mime_type = [mimeType cStringUsingEncoding:NSUTF8StringEncoding];
	
	if (mime_type.StartsWith("audio")) {
		ret = "object.item.audioItem.musicTrack";
	} else if (mime_type.StartsWith("video")) {
		ret = "object.item.videoItem"; //Note: 360 wants "object.item.videoItem" and not "object.item.videoItem.Movie"
	} else if (mime_type.StartsWith("image")) {
		ret = "object.item.imageItem.photo";
	} else {
		ret = "object.item";
	}
	
	return ret;
}


/*----------------------------------------------------------------------
 |   buildSafeResourceUri
 +---------------------------------------------------------------------*/
- (NPT_String)buildSafeResourceUri:(const NPT_HttpUrl&)base_uri withHost:(const char*)host withResource:(const char*)theRes
{
	NPT_String result;
	NPT_HttpUrl uri = base_uri;
	
	if (host) uri.SetHost(host);
	
	NPT_String uri_path = uri.GetPath();
	if (!uri_path.EndsWith("/")) uri_path += "/";
	
	// some controllers (like WMP) will call us with an already urldecoded version.
	// We're intentionally prepending a known urlencoded string
	// to detect it when we receive the request
	uri_path += "%25/";
	uri_path += NPT_Uri::PercentEncode(theRes, " !\"<>\\^`{|}?#[]:/", true);
	
	// set path but don't urlencode it again
	uri.SetPath(uri_path, true);
	
	// 360 hack: force inclusion of port in case it's 80
	return uri.ToStringWithDefaultPort(0);
}


#pragma mark PLT_MediaServerDelegateObject
- (NPT_Result)onBrowseMetadata:(PLT_MediaServerBrowseCapsule*)info
{
	NSLog(@"onBrowseMetadata");
	return NPT_FAILURE;
}


- (NPT_Result)onBrowseDirectChildren:(PLT_MediaServerBrowseCapsule*)info
{

	if ([info.objectId isEqualToString:@"0"]) {
		
		NSMutableArray *collectorGroups = [[NSMutableArray alloc] initWithCapacity:10];
		
		ALAssetsLibrary *al = [PhotoDMSDelegate defaultAssetsLibrary];
		
		dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
		
		[al enumerateGroupsWithTypes:ALAssetsGroupAll
											usingBlock:^(ALAssetsGroup *group, BOOL *stop){
												if (group) {
													[collectorGroups addObject:group];	
												}else {
													dispatch_semaphore_signal(semaphore);
												}
											}
										failureBlock:^(NSError *error) { 
											NSLog(@"error in enumerateGroupsWithTypes !!!");
											dispatch_semaphore_signal(semaphore);
										}
		 ];
		
		dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);
		
		assetGroups = collectorGroups;
		
		unsigned long cur_index = 0;
    unsigned long num_returned = 0;
    unsigned long total_matches = 0;
		
		NPT_String didl = didl_header;
		
		for (int i = 0; i < [collectorGroups count]; i++) {
			
			ALAssetsGroup *group = [collectorGroups objectAtIndex:i];
			NSString *groupName	 = [group valueForProperty:ALAssetsGroupPropertyName];
			
			//NSLog (@"%@", groupName);
			
			PLT_MediaObjectReference item;
			
			PLT_MediaObject* object = NULL;
			object = new PLT_MediaContainer;
			
			NPT_String title([groupName cStringUsingEncoding:NSUTF8StringEncoding]);
			//title.Append(" - ");
			//title.Append([artistName cStringUsingEncoding:NSUTF8StringEncoding]);
			object->m_Title =  title;
			
			((PLT_MediaContainer*)object)->m_ChildrenCount = (NPT_Int32)0;
			object->m_ObjectClass.type = "object.container.storageFolder";
			
			object->m_ParentID = "0";
			NPT_String objID("Pht_I_");
			objID.Append(NPT_String::FromInteger((NPT_Int64)i));
			object->m_ObjectID = objID;
			item = object;
			
			NPT_String tmp;
			NPT_CHECK_SEVERE(PLT_Didl::ToDidl(*item.AsPointer(), [info.filter cStringUsingEncoding:NSUTF8StringEncoding], tmp));                
			didl += tmp;
			++num_returned;
			++cur_index;
			++total_matches; 
		}
		
		didl += didl_footer;
		NPT_CHECK_SEVERE([info setValue:[NSString stringWithCString:didl.GetChars() encoding:NSUTF8StringEncoding] forArgument:@"Result"]);
		
		NPT_CHECK_SEVERE([info setValue:[[NSNumber numberWithLong:num_returned]stringValue] forArgument:@"NumberReturned"]);
		NPT_CHECK_SEVERE([info setValue:[[NSNumber numberWithLong:total_matches]stringValue] forArgument:@"TotalMatches"]);
		NPT_CHECK_SEVERE([info setValue:@"1" forArgument:@"UpdateId"]);
		
		return  NPT_SUCCESS;
	}else if([[info.objectId substringToIndex:6] isEqualToString:@"Pht_I_"]) {
		NSString *albIndex = [info.objectId	substringFromIndex:6];
		ALAssetsGroup *group = [assetGroups objectAtIndex:[albIndex intValue]];
		NSString *groupName	 = [group valueForProperty:ALAssetsGroupPropertyName];

		NSMutableArray *collectorAsset = [[NSMutableArray alloc] initWithCapacity:0];
		
		dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
		[group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
			if (asset) {
				[collectorAsset addObject:asset];
				//NSLog(@"asset : %@", asset);
			} else {
				dispatch_semaphore_signal(semaphore);
			}
		}];
		dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);
		
		unsigned long cur_index = 0;
    unsigned long num_returned = 0;
    unsigned long total_matches = 0;
		
		PLT_HttpRequestContext *context = [info getContext];
		
		NPT_String didl = didl_header;
		
    for (ALAsset *anAsset in collectorAsset) {
			NSDate *date				 = [anAsset valueForProperty:ALAssetPropertyDate];
			NSString *dateString = [[Util sharedInstance] formateDate:date];
			
			NSString *uti = [[anAsset defaultRepresentation] UTI];
			NSDictionary *assetDict = [anAsset valueForProperty:ALAssetPropertyURLs];
			NSURL *URL = [assetDict valueForKey:uti];
			
			NSString *urlString = [URL absoluteString];

			NSRange nameRange		= [urlString rangeOfString:@"&ext="];
			NSString *extName   = [urlString substringFromIndex:NSMaxRange(nameRange)];
			
			PLT_MediaObjectReference item;
			PLT_MediaObject*      object = NULL;
			object = new PLT_MediaItem();
			PLT_MediaItemResource resource;
			
			
			/* Set the title using the filename for now */
			object->m_Title = [dateString cStringUsingEncoding:NSUTF8StringEncoding];
			if (object->m_Title.GetLength() == 0){
				return NPT_FAILURE;
			};
			
			/* Set the protocol Info from the extension */
			
			NSString *extMimeString = [[self getTypeDictionary] objectForKey:[extName lowercaseString]];
			//NSLog(@"extMimeString  %@", extMimeString);

			resource.m_ProtocolInfo = PLT_ProtocolInfo::GetProtocolInfoFromMimeType([extMimeString cStringUsingEncoding:NSUTF8StringEncoding], true, context);
			if (!resource.m_ProtocolInfo.IsValid()){
				return NPT_FAILURE;
			}
			
			/* Set the resource file size */
			resource.m_Size = 100000;
			
			NPT_String filepath([urlString cStringUsingEncoding:NSUTF8StringEncoding]);
			NPT_String root("/");
			/* format the resource URI */
			NPT_String url = filepath.SubString(root.GetLength()+1);
			
			// get list of ip addresses
			NPT_List<NPT_IpAddress> ips;
			//TODO:Veryfy
			NPT_Result r = PLT_UPnPMessageHelper::GetIPAddresses(ips);
			if (r == NPT_FAILURE) {
				return NPT_FAILURE;
			}
			
			
			/* if we're passed an interface where we received the request from
			 move the ip to the top so that it is used for the first resource */
			if (context->GetLocalAddress().GetIpAddress().ToString() != "0.0.0.0") {
				ips.Remove(context->GetLocalAddress().GetIpAddress());
				ips.Insert(ips.GetFirstItem(), context->GetLocalAddress().GetIpAddress());
			}
			object->m_ObjectClass.type = [self getUPnPClass:extMimeString];
			
			/* add as many resources as we have interfaces s*/
			NPT_String m_UrlRoot("/");
			NPT_HttpUrl base_uri("127.0.0.1", context->GetLocalAddress().GetPort(), m_UrlRoot);
			NPT_List<NPT_IpAddress>::Iterator ip = ips.GetFirstItem();        
			while (ip) {
				//resource.m_Uri = BuildResourceUri(base_uri, ip->ToString(), url);
				resource.m_Uri = [self buildSafeResourceUri:base_uri withHost:ip->ToString() withResource:[urlString cStringUsingEncoding:NSUTF8StringEncoding]];
								
				object->m_Resources.Add(resource);
				++ip;
			}
			
			
			NPT_String parentID([groupName cStringUsingEncoding:NSUTF8StringEncoding]);
			parentID.Append([info.objectId cStringUsingEncoding:NSUTF8StringEncoding]);
			
			NPT_String objID([groupName cStringUsingEncoding:NSUTF8StringEncoding]);
			objID.Append([info.objectId cStringUsingEncoding:NSUTF8StringEncoding]);
			objID.Append("/");
			objID.Append([dateString cStringUsingEncoding:NSUTF8StringEncoding]);
			
			object->m_ParentID = parentID;
			object->m_ObjectID = objID;
			
			///////end
			
			item = object;
			
			NPT_String tmp;
			NPT_CHECK_SEVERE(PLT_Didl::ToDidl(*item.AsPointer(), [info.filter cStringUsingEncoding:NSUTF8StringEncoding], tmp));                
			didl += tmp;
			++num_returned;
			++cur_index;
			++total_matches; 
    }
		
		didl += didl_footer;
			
		NPT_CHECK_SEVERE([info setValue:[NSString stringWithCString:didl.GetChars() encoding:NSUTF8StringEncoding] forArgument:@"Result"]);
		
		NPT_CHECK_SEVERE([info setValue:[[NSNumber numberWithLong:num_returned]stringValue] forArgument:@"NumberReturned"]);
		NPT_CHECK_SEVERE([info setValue:[[NSNumber numberWithLong:total_matches]stringValue] forArgument:@"TotalMatches"]);
		NPT_CHECK_SEVERE([info setValue:@"1" forArgument:@"UpdateId"]);
		
		return  NPT_SUCCESS;
		
	}

	return NPT_SUCCESS;
}

- (NPT_Result)onSearchContainer:(PLT_MediaServerSearchCapsule*)info
{
	NSLog(@"onSearchContainer");
	return NPT_FAILURE;
}



- (NPT_Result)onFileRequest:(PLT_MediaServerFileRequestCapsule*)info withURL:(NSString *)theURL {

	info.getResponse->GetHeaders().SetHeader("Accept-Ranges", "bytes");
	
	if (info.getContext->GetRequest().GetMethod().Compare("GET") && info.getContext->GetRequest().GetMethod().Compare("HEAD")) {
		info.getResponse->SetStatus(500, "Internal Server Error");
		return NPT_SUCCESS;
	}
	
	NSRange range				= [theURL rangeOfString:@"assets-library://"];
	NSString *urlSubstring = [theURL substringFromIndex:range.location];
	
	NSRange extNameRange		= [theURL rangeOfString:@"&ext="];
	NSString *extName   = [theURL substringFromIndex:NSMaxRange(extNameRange)];
		
	NSRange nameRange		= [theURL rangeOfString:@"?id="];
	NSString *nameStringPart = [theURL substringFromIndex:NSMaxRange(nameRange)];
	
	
	NSString *fileNamePrefix = @"D_P_RES_%@";
	NSString *fileName = [NSString stringWithFormat:fileNamePrefix, nameStringPart];
	//NSString *tempDir = [self getDocumentPath];
	NSString *tempDir = [self getTempPath];
	NSString *filePath = [tempDir stringByAppendingPathComponent:fileName];
	
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		
		__block UIImage		 *imageToSend = nil;
		__block AVURLAsset *videoAsset = nil;
		
		__block BOOL hasErrorFlag		= NO;

		NSURL *theResourceURL = [NSURL URLWithString:urlSubstring];
		
		ALAssetsLibrary *al =	[PhotoDMSDelegate defaultAssetsLibrary];

		dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
		[al assetForURL:theResourceURL resultBlock:^(ALAsset *asset) {
			NSString *theType =	[asset valueForProperty:ALAssetPropertyType];
			if ([theType isEqualToString:ALAssetTypeVideo]) {
				
				videoAsset = [AVURLAsset URLAssetWithURL:theResourceURL options:nil];
			}else {
				ALAssetRepresentation *rep = [asset defaultRepresentation];
				CGImageRef iref = [rep fullResolutionImage];
				if (iref) {
					imageToSend = [UIImage imageWithCGImage:iref];
				}
			}
			hasErrorFlag = YES;
			dispatch_semaphore_signal(semaphore);
		} failureBlock:^(NSError *error) {
			 NSLog(@"booya, cant get image - %@",[error localizedDescription]);
			hasErrorFlag = NO;
			dispatch_semaphore_signal(semaphore);
		}];
		dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);
		
		if (!hasErrorFlag) {
			info.getResponse->SetStatus(404, "File Not Found");
			return NPT_SUCCESS;
		}
		
		if (!imageToSend && !videoAsset) {
			info.getResponse->SetStatus(404, "File Not Found");
			return NPT_SUCCESS;
		}
		
		if (imageToSend) {
			BOOL flag = [UIImageJPEGRepresentation(imageToSend, 1.0) writeToFile:filePath atomically:YES];
			imageToSend = nil;
			NSLog(@"UIImageJPEGRepresentation %@", filePath);
			if (!flag) {
				info.getResponse->SetStatus(404, "File Not Found");
				return NPT_SUCCESS;
			}
		}else if(videoAsset) {
			
			AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
																						 initWithAsset:videoAsset
																						 presetName:AVAssetExportPresetLowQuality];
			exportSession.outputURL = [NSURL fileURLWithPath:filePath];
			exportSession.outputFileType = AVFileTypeQuickTimeMovie;
			
			__block BOOL retResult = NO;
			
			dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
			
			[exportSession exportAsynchronouslyWithCompletionHandler:^{
				
				if (exportSession.status == AVAssetExportSessionStatusCompleted) {
					NSLog(@"export session completed");
					retResult = YES;
				} else {
					NSLog(@"export session error");
				}
				
				dispatch_semaphore_signal(semaphore);
			}];
			dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);
            videoAsset = nil;
		}
	}
	  
	PLT_HttpServer::ServeFile(info.getContext->GetRequest(),
                            *info.getContext,
                            *info.getResponse,
                            NPT_String([filePath cStringUsingEncoding:NSUTF8StringEncoding]));
	/* Update content type header according to file and context */
	NPT_HttpEntity* entity = info.getResponse->GetEntity();
	
	NSString *extMimeString = [[self getTypeDictionary] objectForKey:[extName lowercaseString]];
	
	if (entity) entity->SetContentType([extMimeString cStringUsingEncoding:NSUTF8StringEncoding]);// this is for m4a
	
	if ([self updateCurrentFileDate:filePath]) {
		[self sweepCache];
	}
	
	return NPT_SUCCESS;
}

@end
