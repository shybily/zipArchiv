//
//  ImageBrowserController.m
//  betty
//
//  Created by 杨博 on 13-8-5.
//  Copyright (c) 2013年 杨博. All rights reserved.
//

#import "ImageBrowserController.h"

static NSArray *openFiles()
{
    NSOpenPanel *panel;
    
    panel = [NSOpenPanel openPanel];
    [panel setFloatingPanel:YES];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:YES];
    [panel setAllowsMultipleSelection:NO];
    [panel setAllowedFileTypes:[NSArray arrayWithObjects: @"jpg",@"JPG",@"png",@"gif",@"jpeg", nil]];
    [panel setAllowsMultipleSelection:YES];
    [panel setDirectoryURL:[NSURL fileURLWithPath:[@"~" stringByExpandingTildeInPath]]];
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
    
    NSLog(@"%@",savePanel);
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

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        [self initStatusBar];
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

- (void)addAnImageWithPath:(NSString *)path
{
    Images *p;
	/* add a path to our temporary array */
    p = [[Images alloc] init];
    [p setPath:path];
    [_importedImages addObject:p];
//    NSLog(@"%@",p);
//    [p autorelease];
}

- (void)addImagesWithPath:(NSString *)path recursive:(BOOL)recursive
{
//    NSLog(@"%@",path);
    NSInteger i, n;
    BOOL dir;
    
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir];
    
    if (dir)
    {
        NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        
        n = [content count];
        
		// parse the directory content
        for (i=0; i<n; i++)
        {
            if (recursive)
                [self addImagesWithPath:[path stringByAppendingPathComponent:[content objectAtIndex:i]] recursive:YES];
            else
                [self addAnImageWithPath:[path stringByAppendingPathComponent:[content objectAtIndex:i]]];
        }
    }
    else
    {
        [self addAnImageWithPath:path];
    }
}

/* performed in an independant thread, parse all paths in "paths" and add these paths in our temporary array */
- (void)addImagesWithPaths:(NSArray *)urls
{
    NSInteger i, n;
    
//    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//    [urls retain];
    
    n = [urls count];
    NSLog(@"%ld",(long)n);
    for ( i= 0; i < n; i++)
    {
        NSURL *url = [urls objectAtIndex:i];
        [self addImagesWithPath:[url path] recursive:NO];
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
    NSLog(@"%@",_images);
    if([_images count] <= 0){
        NSAlert* alert = [NSAlert alertWithMessageText:@"错误!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"请先选择要打包的文件" ];
        [alert beginSheetModalForWindow:nil modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }else{  
        @autoreleasepool {
            NSURL *savePath = getSavePath();
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSMutableArray *items = [NSMutableArray new];
            for (NSObject *value in _images) {
                
                if([fileManager fileExistsAtPath:[value imageRepresentation]]){
                    NSString *tmp = [[NSString alloc]initWithData:[[value imageRepresentation] dataUsingEncoding:NSUnicodeStringEncoding] encoding:NSUnicodeStringEncoding];
                    NSLog(@"%@",tmp);
                    [items addObject:tmp];
                }
            }
            NSLog(@"items : %lu",(unsigned long)[items count]);
            if ([items count] >= 1) {
                ZipArchive *zipFile = [ZipArchive archiveWithArchivePath:[savePath path]];
                NSLog(@"zipFile : %@",zipFile);
                [ZipArchive process:zipFile withItems:items usingResourceFork:YES withInvoker:nil andDelegate:self];
            }
        }
    }
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
    
    trayItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [trayItem setMenu:menu];
    [trayItem setHighlightMode:YES];
    [trayItem setTitle:@"HERE"];
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




























@end
