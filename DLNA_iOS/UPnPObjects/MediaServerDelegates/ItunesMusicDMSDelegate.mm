//
//  ItunesMusicDMSDelegate.m
//  DLNA_iOS
//
//  Created by wangshuaidavid on 12-8-21.
//
//

#import "ItunesMusicDMSDelegate.h"
#import "Util.h"
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetExportSession.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AVFoundation/AVAssetTrack.h>

#include <CoreMedia/CMFormatDescription.h>
#import <CoreAudio/CoreAudioTypes.h>


#import <MediaPlayer/MediaPlayer.h>
@implementation ItunesMusicDMSDelegate
@synthesize albumsArray;

#pragma mark - DocumentPath
- (NSString *)getDocumentPath {
	return [[Util sharedInstance] getDocumentPath];
}


- (NSString *)getTempPath {
	return NSTemporaryDirectory();
}


- (void)loadSongs {
	
	if (albumsArray) {
		return;
	}
	
	MPMediaQuery *query = [MPMediaQuery albumsQuery];
	
	NSArray *albums = [query collections];
	self.albumsArray = albums;
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
		NPT_String didl = didl_header;
		PLT_MediaObjectReference item;
		
		PLT_MediaObject* object = NULL;
		object = new PLT_MediaContainer;
		object->m_Title = "Albums";
		
		((PLT_MediaContainer*)object)->m_ChildrenCount = (NPT_Int32)100;
		object->m_ObjectClass.type = "object.container.storageFolder";
		
		object->m_ParentID = "0";
		object->m_ObjectID = "Albums";
		
		item = object;
		
		
		NPT_String tmp;
		NPT_CHECK_SEVERE(PLT_Didl::ToDidl(*item.AsPointer(), [info.filter cStringUsingEncoding:NSUTF8StringEncoding], tmp));
		
		/* add didl header and footer */
		didl = didl_header + tmp + didl_footer;
		
		NPT_CHECK_SEVERE([info setValue:[NSString stringWithCString:didl.GetChars() encoding:NSUTF8StringEncoding] forArgument:@"Result"]);
		NPT_CHECK_SEVERE([info setValue:[NSString stringWithCString:"1" encoding:NSUTF8StringEncoding] forArgument:@"NumberReturned"]);
		NPT_CHECK_SEVERE([info setValue:[NSString stringWithCString:"1" encoding:NSUTF8StringEncoding] forArgument:@"TotalMatches"]);
		
		// update ID may be wrong here, it should be the one of the container?
		// TODO: We need to keep track of the overall updateID of the CDS
		NPT_CHECK_SEVERE([info setValue:[NSString stringWithCString:"1" encoding:NSUTF8StringEncoding] forArgument:@"UpdateId"]);
		
		return  NPT_SUCCESS;
	}else if ([info.objectId isEqualToString:@"Albums"]) {
		
		[self loadSongs];
		
		unsigned long cur_index = 0;
        unsigned long num_returned = 0;
        unsigned long total_matches = 0;
		
		NPT_String didl = didl_header;
		
		for (int i = 0; i < [albumsArray count]; i++) {
			
			MPMediaItemCollection *album = [albumsArray objectAtIndex:i];
			MPMediaItem *representativeItem = [album representativeItem];
			//NSString *artistName = [representativeItem valueForProperty: MPMediaItemPropertyArtist];
			NSString *albumName = [representativeItem valueForProperty: MPMediaItemPropertyAlbumTitle];
			//NSLog (@"%@ by %@", albumName, artistName);
			
			PLT_MediaObjectReference item;
			
			PLT_MediaObject* object = NULL;
			object = new PLT_MediaContainer;
			
			NPT_String title([albumName cStringUsingEncoding:NSUTF8StringEncoding]);
			//title.Append(" - ");
			//title.Append([artistName cStringUsingEncoding:NSUTF8StringEncoding]);
			object->m_Title =  title;
			
			((PLT_MediaContainer*)object)->m_ChildrenCount = (NPT_Int32)0;
			object->m_ObjectClass.type = "object.container.storageFolder";
			
			object->m_ParentID = "Albums";
			NPT_String objID("alb_");
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
	} else if([[info.objectId substringToIndex:4] isEqualToString:@"alb_"]) {
		NSString *albIndex = [info.objectId	substringFromIndex:4];
		MPMediaItemCollection *album = [albumsArray objectAtIndex:[albIndex intValue]];
		
		//MPMediaItem *representativeItem = [album representativeItem];
		//NSString *artistName = [representativeItem valueForProperty: MPMediaItemPropertyArtist];
		//NSString *albumName = [representativeItem valueForProperty: MPMediaItemPropertyAlbumTitle];
		
		NSArray *songs = [album items];
		
		unsigned long cur_index = 0;
    unsigned long num_returned = 0;
    unsigned long total_matches = 0;
		
		PLT_HttpRequestContext *context = [info getContext];
		
		NPT_String didl = didl_header;
		
    for (MPMediaItem *song in songs) {
			NSString *songTitle = [song valueForProperty: MPMediaItemPropertyTitle];
			//NSLog (@"\t\t%@", songTitle);
			
			NSURL *assetURL = [song valueForProperty:MPMediaItemPropertyAssetURL];
			//AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
			
			PLT_MediaObjectReference item;
			PLT_MediaObject*      object = NULL;
			object = new PLT_MediaItem();
			PLT_MediaItemResource resource;
			
			
			/* Set the title using the filename for now */
			object->m_Title = [songTitle cStringUsingEncoding:NSUTF8StringEncoding];
			if (object->m_Title.GetLength() == 0){
				return NPT_FAILURE;
			};
			
			/* Set the protocol Info from the extension */
			
			resource.m_ProtocolInfo = PLT_ProtocolInfo::GetProtocolInfoFromMimeType("audio/mpeg", true, context);
			if (!resource.m_ProtocolInfo.IsValid()){
				return NPT_FAILURE;
			}
			
			/* Set the resource file size */
			resource.m_Size = 100000;
			
			NPT_String filepath([[assetURL path] cStringUsingEncoding:NSUTF8StringEncoding]);
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
			object->m_ObjectClass.type = [self getUPnPClass:@"audio/mpeg"];
			
			/* add as many resources as we have interfaces s*/
			NPT_String m_UrlRoot("/");
			NPT_HttpUrl base_uri("127.0.0.1", context->GetLocalAddress().GetPort(), m_UrlRoot);
			NPT_List<NPT_IpAddress>::Iterator ip = ips.GetFirstItem();
			while (ip) {
				resource.m_Uri = [self buildSafeResourceUri:base_uri withHost:ip->ToString() withResource:[[assetURL absoluteString] cStringUsingEncoding:NSUTF8StringEncoding]];
				
				//	NSLog(@"resource.m_Uri : %@", [NSString stringWithCString:resource.m_Uri.GetChars() encoding:NSUTF8StringEncoding]);
				
				object->m_Resources.Add(resource);
				++ip;
			}
			
			
			NPT_String parentID("Albums/");
			parentID.Append([info.objectId cStringUsingEncoding:NSUTF8StringEncoding]);
			
			NPT_String objID("Albums/");
			objID.Append([info.objectId cStringUsingEncoding:NSUTF8StringEncoding]);
			objID.Append("/");
			objID.Append([songTitle cStringUsingEncoding:NSUTF8StringEncoding]);
			
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
		
		//NSLog(@"didl  : %@", [NSString stringWithCString:didl.GetChars() encoding:NSUTF8StringEncoding]);
		
		NPT_CHECK_SEVERE([info setValue:[NSString stringWithCString:didl.GetChars() encoding:NSUTF8StringEncoding] forArgument:@"Result"]);
		
		NPT_CHECK_SEVERE([info setValue:[[NSNumber numberWithLong:num_returned]stringValue] forArgument:@"NumberReturned"]);
		NPT_CHECK_SEVERE([info setValue:[[NSNumber numberWithLong:total_matches]stringValue] forArgument:@"TotalMatches"]);
		NPT_CHECK_SEVERE([info setValue:@"1" forArgument:@"UpdateId"]);
		
		return  NPT_SUCCESS;
		
	}
	
	return NPT_FAILURE;
	
}

- (NPT_Result)onSearchContainer:(PLT_MediaServerSearchCapsule*)info
{
	NSLog(@"onSearchContainer");
	return NPT_FAILURE;
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


NSInteger dateSort(id s1, id s2, void *context) {
	
	NSDate *d1;
	[s1 getResourceValue:&d1 forKey:NSURLAttributeModificationDateKey error:NULL];
	NSDate *d2;
	[s2 getResourceValue:&d2 forKey:NSURLAttributeModificationDateKey error:NULL];
	
	return [d2 compare:d1];
}


- (void)sweepCache {
	
	static int cacheInt = 5;
	
	NSURL *url = [NSURL URLWithString:[self getTempPath]];
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtURL:url includingPropertiesForKeys:[NSArray arrayWithObject:NSURLContentModificationDateKey] options:NSDirectoryEnumerationSkipsSubdirectoryDescendants|NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsPackageDescendants errorHandler:nil];
	
	
	NSMutableArray *fileArray = [NSMutableArray arrayWithCapacity:15];
	
	for (NSURL *theFileURL in dirEnum) {
		
		NSString *fileName;
		[theFileURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
		
		if ([fileName rangeOfString:@"T_M_File_"].location != NSNotFound) {
			[fileArray addObject:theFileURL];
		}
		
	}
	
	if ([fileArray count] < cacheInt) {
		return;
	}
	
	NSArray* sortedArray = [fileArray sortedArrayUsingFunction:dateSort context:nil];
	
	for (int i = cacheInt; i < [sortedArray count]; i ++) {
		NSError *deleteErr = nil;
		
		NSLog (@"delete %@", [sortedArray objectAtIndex:i]);
		
		[[NSFileManager defaultManager] removeItemAtURL:[sortedArray objectAtIndex:i] error:&deleteErr];
		if (deleteErr) {
			NSLog (@"Can't delete %@: %@", [sortedArray objectAtIndex:i], deleteErr);
		}
	}
	
}


- (NPT_Result)onFileRequest:(PLT_MediaServerFileRequestCapsule*)info withURL:(NSString *)theURL {
	
	info.getResponse->GetHeaders().SetHeader("Accept-Ranges", "bytes");
	
	if (info.getContext->GetRequest().GetMethod().Compare("GET") && info.getContext->GetRequest().GetMethod().Compare("HEAD")) {
		info.getResponse->SetStatus(500, "Internal Server Error");
		return NPT_SUCCESS;
	}
	
	NSRange range				= [theURL rangeOfString:@"ipod-library:"];
	NSString *substring = [theURL substringFromIndex:range.location];
	
	//NSLog (@"%@", substring);
	
	NSRange nameRange		= [theURL rangeOfString:@"?id="];
	NSString *nameStringPart = [theURL substringFromIndex:NSMaxRange(nameRange)];
	
	NSString *fileNamePrefix = @"T_M_File_%@";
	NSString *fileName = [NSString stringWithFormat:fileNamePrefix, nameStringPart];
	//	NSString *tempDir = [self getDocumentPath];
	NSString *tempDir = [self getTempPath];
	NSString *filePath = [tempDir stringByAppendingPathComponent:fileName];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		
		//NSLog(@"file NOT exist::::::::::==============>>>>>>>>>>>>>>>>>");
		NSURL *theResourceURL = [NSURL URLWithString:substring];
		AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:theResourceURL options:nil];
		
		
		AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
																					 initWithAsset:songAsset
																					 presetName:AVAssetExportPresetAppleM4A];
		exportSession.outputURL = [NSURL fileURLWithPath:filePath];
		exportSession.outputFileType = AVFileTypeAppleM4A;
		
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
		
		if (!retResult) {
			info.getResponse->SetStatus(404, "File Not Found");
			return NPT_SUCCESS;
		}
	}
	
  //PLT_HttpServer::ServeFile(info.getContext->GetRequest(), *info.getResponse, NPT_String([filePath cStringUsingEncoding:NSUTF8StringEncoding]));
	
  PLT_HttpServer::ServeFile(info.getContext->GetRequest(),
                            *info.getContext,
                            *info.getResponse,
                            NPT_String([filePath cStringUsingEncoding:NSUTF8StringEncoding]));
  
	/* Update content type header according to file and context */
	NPT_HttpEntity* entity = info.getResponse->GetEntity();
	if (entity) entity->SetContentType("audio/mp4");// this is for m4a
	
	
	if ([self updateCurrentFileDate:filePath]) {
		[self sweepCache];
	}
	
	return NPT_SUCCESS;
}

@end
