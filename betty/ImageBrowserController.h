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
//    IBOutlet NSWindow *window;
    
    NSMutableArray *_images;
    NSMutableArray *_importedImages;
    NSMutableArray *_selectFiles;
//    ZKArchive *_zipFile;
}

@property (strong) NSOperationQueue *zipQueue;

- (IBAction)zoomSlider:(id)sender;
- (IBAction)addImage:(id)sender;
- (IBAction)quitAction:(id)sender;
- (IBAction)compression:(id)sender;
- (IBAction)clean:(id)sender;

- (void)initStatusBar;


@end
