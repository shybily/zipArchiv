//
//  ImageBrowserController.m
//  betty
//
//  Created by 杨博 on 13-8-5.
//  Copyright (c) 2013年 杨博. All rights reserved.
//

#import "ImageBrowserController.h"
#import "FileList.h"

static NSArray *openFiles()
{
    NSOpenPanel *panel;
    
    panel = [NSOpenPanel openPanel];
    [panel setFloatingPanel:YES];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:YES];
    [panel setAllowsMultipleSelection:NO];
    [panel setAllowedFileTypes:[NSArray arrayWithObjects: @"jpg",@"JPG",@"png",@"gif",@"jpeg",@"doc",@"docx",@"xls",@"xlsx",@"txt",@"pdf", nil]];
    [panel setAllowsMultipleSelection:YES];
    [panel setDirectoryURL:[NSURL fileURLWithPath:[@"~" stringByExpandingTildeInPath]]];
	[panel setTitle:@"Choose a directory of images"];
	[panel setPrompt:@"Choose"];
	NSInteger i = [panel runModal];
	if (i == NSOKButton)
    {
		return [panel URLs];
    }
    
    return nil;
}

static NSURL *getSavePath()
{
    NSSavePanel *savePanel;
    
//    NSLog(@"%@",savePanel);
    savePanel = [NSSavePanel new];
    [savePanel setAllowedFileTypes:[NSArray arrayWithObjects: @"zip", nil]];
//    defaultDirectoryPath = @"/User/shybily/Desktop";
    
//    [savePanel setNameFieldStringValue:defaultName];
//    [savePanel setDirectoryURL:[NSURL fileURLWithPath:defaultDirectoryPath]];
    NSInteger i = [savePanel runModal];
    if (i == NSOKButton) {
        return [savePanel URL];
    }
    return nil;
    
//    return savePanel;
}

@interface ImageBrowserController ()

@end

@implementation ImageBrowserController

-(id)init{
    self = [super init];
    if(self){
        [self initStatusBar];
        [currDir addObject:NSHomeDirectory()];
    }
    return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
//        [self initStatusBar];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
//    NSLog(@"%s","windowDidLoad");
    [_images removeAllObjects];
    [_importedImages removeAllObjects];
    [self updateDatasource];
    [self addImage:self];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)awakeFromNib
{
    // create two arrays : the first one is our datasource representation,
    // the second one are temporary imported images (for thread safeness)
    
    _images = [[NSMutableArray alloc] init];
    _importedImages = [[NSMutableArray alloc] init];

    //allow reordering, animations et set draggind destination delegate
    [_imageBrowser setAllowsReordering:YES];
    [_imageBrowser setAnimates:YES];
    [_imageBrowser setDraggingDestinationDelegate:self];
    [_imageBrowser setCellsStyleMask:IKCellsStyleTitled];
    
    @autoreleasepool {
        [NSThread detachNewThreadSelector:@selector(addImagesWithPaths:) toTarget:self withObject:[NSArray arrayWithObjects:[[NSURL alloc]initFileURLWithPath:NSHomeDirectory()], nil]];
    }
//        [imageBrowser setCellsStyleMask:IKCellsStyleTitled];
}

/* entry point for reloading image-browser's data and setNeedsDisplay */
- (void)updateDatasource
{
    //-- update our datasource, add recently imported items
    [_images addObjectsFromArray:_importedImages];
	
	//-- empty our temporary array
    [_importedImages removeAllObjects];
    //-- reload the image browser and set needs display
    [_imageBrowser reloadData];
}

- (void)addAnImageWithPath:(NSURL *)path
{
    
    Images *p;
	/* add a path to our temporary array */
    p = [[Images alloc] init];
    [p setPath:path];
    [_importedImages addObject:p];
    
}

- (BOOL)isImageFile:(NSURL *)url
{
    BOOL isImageFile = NO;
    
//    NSString *path = [[NSString new] stringByAppendingFormat:@"file:/%@",[url absoluteString]];
//    NSURL *tmp = [[NSURL new]initWithString:path];
    
    NSString *utiValue;
    [url getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:nil];
    if (utiValue)
    {
//        NSLog(@"%@",(CFStringRef)CFBridgingRetain(utiValue));
//        [utiValue isEqualToString:(NSString *)];
        isImageFile = UTTypeConformsTo((CFStringRef)CFBridgingRetain(utiValue), kUTTypeImage) || UTTypeConformsTo((CFStringRef)CFBridgingRetain(utiValue), kUTTypeText);
    }
    return isImageFile;
}

- (BOOL)isAllowableFileType:(NSURL *)url{
    BOOL isAllowed = NO;
    NSString *utiValue;
    [url getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:nil];
    if(utiValue){
//        NSLog(@"%@",utiValue);
        BOOL isImage = UTTypeConformsTo((CFStringRef)CFBridgingRetain(utiValue), kUTTypeImage);
        BOOL isText = UTTypeConformsTo((CFStringRef)CFBridgingRetain(utiValue), kUTTypeText);
        BOOL isPdf = UTTypeConformsTo((CFStringRef)CFBridgingRetain(utiValue), kUTTypePDF);
        BOOL isWordDocument = [utiValue isEqualToString:@"com.microsoft.word.doc"] || [utiValue isEqualToString:@"org.openxmlformats.wordprocessingml.document"];
        BOOL isExcelDocument = [utiValue isEqualToString:@"com.microsoft.excel.xls"] || [utiValue isEqualToString:@"org.openxmlformats.spreadsheetml.sheet"];
        
        isAllowed = isImage || isText || isPdf || isWordDocument || isExcelDocument;
        
//        isAllowed =  UTTypeConformsTo((CFStringRef)CFBridgingRetain(utiValue), kUTTypeText) || [utiValue isEqualToString:@"com.microsoft.word.doc"] || [utiValue isEqualToString:@"com.adobe.pdf"];
    }
    return isAllowed;
}

- (void)addImageWithURL:(NSURL *)imageURL
{
    NSNumber *hiddenFlag = nil;
    if ([imageURL getResourceValue:&hiddenFlag forKey:NSURLIsHiddenKey error:nil])
    {
        NSNumber *isDirectoryFlag = nil;
        if ([imageURL getResourceValue:&isDirectoryFlag forKey:NSURLIsDirectoryKey error:nil])
        {
            NSNumber *isPackageFlag = nil;
            if ([imageURL getResourceValue:&isPackageFlag forKey:NSURLIsPackageKey error:nil])
            {
                // only "add visible" file system objects, folders and images (no packages)
                if (![hiddenFlag boolValue] && ![isPackageFlag boolValue] &&
                    ([isDirectoryFlag boolValue] || [self isAllowableFileType:imageURL]))
                {
//                NSLog(@"aaa %c",[hiddenFlag boolValue]);
//                if (![hiddenFlag boolValue] && ![isPackageFlag boolValue] &&
//                    ([isDirectoryFlag boolValue]))
//                {
                    Images *p = [[Images alloc] init];
                    [p setPath:imageURL];
                    [_importedImages addObject:p];
                }
            }
        }
    }
}

- (void)addImagesFromDirectory:(NSURL *)directoryURL
{
	NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directoryURL
                                                     includingPropertiesForKeys:nil
                                                                        options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                          error:nil];
    for (NSURL *imageURL in content)
    {
        [self addImageWithURL:imageURL];
    }
    
//	[self updateDatasource];
}

- (void)addImagesWithPath:(NSURL *)path recursive:(BOOL)recursive
{
//    NSLog(@"%@",path);
//    NSInteger i, n;
    BOOL dir;
    
    [[NSFileManager defaultManager] fileExistsAtPath:[path path] isDirectory:&dir];
    
    if (dir)
    {
        [self addImagesFromDirectory:path];
    }
    else
    {
        [self addImageWithURL:path];
//        [self addAnImageWithPath:path];
    }
}

/* performed in an independant thread, parse all paths in "paths" and add these paths in our temporary array */
- (void)addImagesWithPaths:(NSArray *)urls
{
    NSInteger i, n;
    
//    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//    [urls retain];
    
    n = [urls count];
//    NSLog(@"%ld",(long)n);
    for ( i= 0; i < n; i++)
    {
        NSURL *url = [urls objectAtIndex:i];
//        NSLog(@"%@",url);
        [self addImagesWithPath:url recursive:NO];
    }
    
	/* update the datasource in the main thread */
    [self performSelectorOnMainThread:@selector(updateDatasource) withObject:nil waitUntilDone:YES];
    
//    [urls release];
//    [pool release];
}

- (void)addImage:(id)sender{
    NSArray *urls = openFiles();
    
    if (!urls)
    {
//        NSLog(@"No files selected, return...");
        return;
    }
    [self showWindow:self];
//    NSLog(@"%@",_window);
//    window = [[MainWindowController alloc]initWithWindowNibName:@"MainWindowController"];
    
//    [mainWindow showWindow:self];
	
	/* launch import in an independent thread */
    @autoreleasepool {
        [NSThread detachNewThreadSelector:@selector(addImagesWithPaths:) toTarget:self withObject:urls];
    }
}

- (void)compression:(id)sender{
//    NSLog(@"%@",_images);
    if([_images count] <= 0){
        NSAlert* alert = [NSAlert alertWithMessageText:@"错误!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"请先选择要打包的文件" ];
        [alert beginSheetModalForWindow:nil modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }else{  
        @autoreleasepool {
            NSURL *savePath = getSavePath();
            NSFileManager *fileManager = [NSFileManager defaultManager];
//            NSMutableArray *items = [NSMutableArray new];
            ZipArchive *zipFile = [ZipArchive new];
            [zipFile CreateZipFile2:[savePath path]];
            for (NSObject *value in _images) {
                
                if([fileManager fileExistsAtPath:[[value imageRepresentation]path]]){
                    if ([self isDir:[value imageRepresentation]]) {
                        NSArray *content = [self readDir:[value imageRepresentation]];
//                        NSLog(@"%@",content);
                        for (FileList *val in content) {
//                            NSLog(@"%@",val);
                            if([self isAllowableFileType:[val getFullPath]]){
                                [zipFile addFileToZip:[[val getFullPath]path] newname:[val getNewName]];
                            }
                        }
                        
                    }else{
                        NSString *newname = [[value imageRepresentation] lastPathComponent];
//                        NSLog(@"%@ : %@",newname,[value imageRepresentation]);
                        [zipFile addFileToZip:[[value imageRepresentation] path] newname:newname];
                    }
                }
            }
            [zipFile CloseZipFile2];
        }
    }
}

- (NSMutableArray *)readDir:(NSURL *)path{
    NSMutableArray *fileList = [NSMutableArray new];
    if ([self isDir:path]) {
        NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:path
                                                         includingPropertiesForKeys:nil
                                                                            options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                              error:nil];
        for (NSURL *value in content) {
            if([self isDir:value]){
                NSArray *tmpArray = [self readDir:value addPreName:[path lastPathComponent]];
                [fileList addObjectsFromArray:tmpArray];
            }else{
                FileList *list = [FileList new];
                [list addFullPath:value withNewName:[NSString stringWithFormat:@"%@/%@",[path lastPathComponent],[value lastPathComponent]]];
                [fileList addObject:list];
            }
        }
    }
    return fileList;
}

- (NSArray *)readDir:(NSURL *)path addPreName:(NSString *)preName{
    NSMutableArray *fileList = [NSMutableArray new];
    if ([self isDir:path]) {
        NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:path
                                                         includingPropertiesForKeys:nil
                                                                            options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                              error:nil];
        for (NSURL *value in content) {
            if([self isDir:value]){
                NSArray *tmpArray = [self readDir:value addPreName:[NSString stringWithFormat:@"%@/%@",preName,[path lastPathComponent]]];
                [fileList addObjectsFromArray:tmpArray];
            }else{
                FileList *list = [FileList new];
                [list addFullPath:value withNewName:[NSString stringWithFormat:@"%@/%@/%@",preName,[path lastPathComponent],[value lastPathComponent]]];
                [fileList addObject:list];
            }
        }
    }
    return fileList;
}

- (BOOL) isDir:(NSURL *)path{
    BOOL dir;
    [[NSFileManager defaultManager] fileExistsAtPath:[path path] isDirectory:&dir];
    return dir;
}

- (void)zoomSlider:(id)sender{
    
    [_imageBrowser setZoomValue:[sender floatValue]];
    
    [_imageBrowser setNeedsDisplay:YES];
}




#pragma mark -
#pragma mark IKImageBrowserDataSource

/* implement image-browser's datasource protocol
 Our datasource representation is a simple mutable array
 */

- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)view
{
	/* item count to display is our datasource item count */
//    NSLog(@"numberOfItemsInImageBrowser");
//    NSLog(@"%lu",(unsigned long)[_images count]);
    return [_images count];
}

- (id)imageBrowser:(IKImageBrowserView *)view itemAtIndex:(NSUInteger)index
{
    return [_images objectAtIndex:index];
}


/* implement some optional methods of the image-browser's datasource protocol to be able to remove and reoder items */

/*	remove
 The user wants to delete images, so remove these entries from our datasource.
 */
- (void)imageBrowser:(IKImageBrowserView *)view removeItemsAtIndexes:(NSIndexSet *)indexes
{
	[_images removeObjectsAtIndexes:indexes];
}

// reordering:
// The user wants to reorder images, update our datasource and the browser will reflect our changes
- (BOOL)imageBrowser:(IKImageBrowserView *)view moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)destinationIndex
{
    NSUInteger index;
    NSMutableArray *temporaryArray;
    
    temporaryArray = [[NSMutableArray alloc] init];
    
    /* first remove items from the datasource and keep them in a temporary array */
    for (index = [indexes lastIndex]; index != NSNotFound; index = [indexes indexLessThanIndex:index])
    {
        if (index < destinationIndex)
            destinationIndex --;
        
        id obj = [_images objectAtIndex:index];
        [temporaryArray addObject:obj];
        [_images removeObjectAtIndex:index];
    }
    
    /* then insert removed items at the good location */
    NSInteger n = [temporaryArray count];
    for (index=0; index < n; index++)
    {
        [_images insertObject:[temporaryArray objectAtIndex:index] atIndex:destinationIndex];
    }
	
    return YES;
}


#pragma mark - IKImageBrowserDelegate

-(void) imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index{
    NSIndexSet *selectionIndexes = [aBrowser selectionIndexes];
//    NSLog(@"change %@",selectionIndexes);
	if ([selectionIndexes count] > 0)
	{
        Images *anItem = [_images objectAtIndex:[selectionIndexes firstIndex]];
        BOOL dir;
        
        [[NSFileManager defaultManager] fileExistsAtPath:[[anItem imageRepresentation]path] isDirectory:&dir];
        if(dir){
            [_images removeAllObjects];
            [_importedImages removeAllObjects];
            [self addImagesWithPath:[anItem imageRepresentation] recursive:NO];
            [self updateDatasource];
        }else{
            [[NSWorkspace sharedWorkspace]openFile:[[anItem imageRepresentation]path]];
        }
    }
    //        return NO;
}

//- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser
//{
//	NSIndexSet *selectionIndexes = [aBrowser selectionIndexes];
//	NSLog(@"change %@",selectionIndexes);
//	if ([selectionIndexes count] > 0)
//	{
//////        NSDictionary *screenOptions = [[NSWorkspace sharedWorkspace] desktopImageOptionsForScreen:curScreen];
//////
//        Images *anItem = [_images objectAtIndex:[selectionIndexes firstIndex]];
////        NSLog(@"selected : %@",[anItem imageTitle]);
////		NSURL *url = [anItem imageRepresentation];
////        NSNumber *isDirectoryFlag = nil;
//        BOOL dir;
//        
//        [[NSFileManager defaultManager] fileExistsAtPath:[anItem imageRepresentation] isDirectory:&dir];
//        NSLog(@"%c",dir);
////        if ([url getResourceValue:&isDirectoryFlag forKey:NSURLIsDirectoryKey error:nil] && ![isDirectoryFlag boolValue])
////        {
////            NSError *error = nil;
//////            [[NSWorkspace sharedWorkspace] setDesktopImageURL:url
//////                                                    forScreen:curScreen
//////                                                      options:screenOptions
//////                                                        error:&error];
////            if (error)
////            {
////                [NSApp presentError:error];
////            }
////        }
//	}
//}

#pragma mark -
#pragma mark drag n drop

///* Drag'n drop support, accept any kind of drop */
//- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
//{
//    return NSDragOperationCopy;
//}
//
//- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
//{
//    return NSDragOperationCopy;
//}
//
//- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
//{
//    NSData *data = nil;
//    NSString *errorDescription;
//	
//    NSPasteboard *pasteboard = [sender draggingPasteboard];
//    
//	/* look for paths in pasteboard */
//    if ([[pasteboard types] containsObject:NSFilenamesPboardType])
//        data = [pasteboard dataForType:NSFilenamesPboardType];
//    
//    if (data)
//    {
//		/* retrieves paths */
//        NSArray *filenames = [NSPropertyListSerialization propertyListFromData:data
//                                                              mutabilityOption:kCFPropertyListImmutable
//                                                                        format:nil
//                                                              errorDescription:&errorDescription];
//        
//        
//		/* add paths to our datasource */
//        NSInteger i;
//        NSInteger n = [filenames count];
//        for (i=0; i<n; i++){
//            [self addAnImageWithPath:[filenames objectAtIndex:i]];
//        }
//		
//		/* make the image browser reload our datasource */
//        [self updateDatasource];
//    }
//    
//	/* we accepted the drag operation */
//	return YES;
//}

//状态栏
- (void)initStatusBar{
    NSZone *zone = [NSMenu menuZone];
    NSMenu *menu = [[NSMenu allocWithZone:zone] init];
    NSMenuItem *item;
    
    item = [menu addItemWithTitle:@"OpenFile" action:@selector(addImage:) keyEquivalent:@""];
    [item setTarget:self];
    
    item = [menu addItemWithTitle:@"Quit" action:@selector(quitAction:) keyEquivalent:@""];
    [item setTarget:self];
    
    trayItem = [[NSStatusBar systemStatusBar]statusItemWithLength:NSSquareStatusItemLength];
    
    [trayItem setMenu:menu];
    [trayItem setHighlightMode:YES];
//    [trayItem setTitle:@"HERE"];
    NSImage *barImage = [NSImage imageNamed:@"barIcon@24*24.png"];
    [barImage setSize:NSMakeSize(18.0, 18.0)];
//    [barImage initWithContentsOfFile:@"0.jpg"];
//    NSLog(@"barImage : %@",barImage);
    [trayItem setImage:barImage];
}

//退出
- (IBAction)quitAction:(id)sender{
    [NSApp terminate:sender];
}

//清除
- (void)clean:(id)sender{
    [_importedImages removeAllObjects];
    [_images removeAllObjects];
    [self updateDatasource];
}

//清除
- (void)home:(id)sender{
    [_importedImages removeAllObjects];
    [_images removeAllObjects];
    [self updateDatasource];
    @autoreleasepool {
        [NSThread detachNewThreadSelector:@selector(addImagesWithPaths:) toTarget:self withObject:[NSArray arrayWithObjects:[[NSURL alloc]initFileURLWithPath:NSHomeDirectory()], nil]];
    }
}




























@end
