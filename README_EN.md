# DLNA_iOS_Platinum
This APP is an implementation of a DLNA media server powered by Platinum libs. It can publish the media files in iTunes and Photo Album to any DLNA player which is in the same network enviroment. 


##Description:
DLNA_iOS was build based on a similar DMS APP for iOS 5
, and that APP doesn't have any updated till the DLNA_iOS. Also it used some enterprise private libs, so it realy hard to pass the build and run. So I refactored the code, and use just general simple libs, for the good of reference.

1. Implementing DMS base on *PlatinumKit-1-0-5-13_0ab854*;
2. Use *Framework* to realize reference *Platinum*;
3. Structuring code by using *Delegate Pattern*, supporting various media sources become easy to realize；

Transporting files via wifi etc, not implemented yet, but will, due to spare time.

----
##Functions
 1. DLNA_iOS shares the media file in the APP *Document directory* to player:
 2. Shares music and video files in *iTunes* to DLNA player；
 3. Shares photos and video in *album* to DLNA player;
 

DLNA_iOS opens three independed server point simultanesously to serve each media sharing from each sources. The player can discover them and browse the files.

####About APP
Will add some features like *transporting files via wifi*, *files management* etc.

----
### Anything about this Project please feel free to contact: <wangshuai@yeah.net>
----

![alt dms on iphone](./ReadmePics/IMG_DMS.jpg)

![alt 8Player Main Board](./ReadmePics/IMG_DMP1.jpg)

![alt 8Player Browse Photo](./ReadmePics/IMG_DMP2.jpg)

![alt 8Player Show Photo List](./ReadmePics/IMG_DMP3.jpg)

![alt 8Player Browse iTunes](./ReadmePics/IMG_DMP4.jpg)