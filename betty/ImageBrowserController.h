//
//  ImageBrowserController.h
//  betty
//
//  Created by 杨博 on 13-8-5.
//  Copyright (c) 2013年 杨博. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <Cocoa/Cocoa.h>

#import "Images.h"
#import "ZipArchive.h"

@interface ImageBrowserController : NSWindowController{
    
    NSStatusItem *trayItem;
    IBOutlet IKImageBrowserView *_imageBrowser;
    IBOutlet NSPanel *progressPanel;
    IBOutlet NSProgressIndicator *progressIndicator;
//    IBOutlet NSWindow *window;
    
    NSMutableArray *_images;
    NSMutableArray *_importedImages;
    NSMutableArray *_selectFiles;
    NSMutableArray *currDir;
    
//    ZKArchive *_zipFile;
}

@property (strong) NSOperationQueue *zipQueue;

- (IBAction)zoomSlider:(id)sender;
- (IBAction)addImage:(id)sender;
- (IBAction)quitAction:(id)sender;
- (IBAction)compression:(id)sender;
- (IBAction)clean:(id)sender;
- (IBAction)home:(id)sender;

- (IBAction)cancelProgress:(id)sender;
- (void) progressDidEnd:(NSWindow *)panel returnCode:(int)returnCode contextInfo:(void *)context;

- (void)initStatusBar;
- (BOOL)isAllowableFileType:(NSURL *)url;
- (NSArray *)readDir:(NSURL *)path;
- (NSArray *)readDir:(NSURL *)path addPreName:(NSString *)preName;

- (void)mkZipArchive:(NSURL *)savePath;


@end
