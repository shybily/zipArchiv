//
//  ZipArchive.h
//  betty
//
//  Created by 杨博 on 13-8-8.
//  Copyright (c) 2013年 杨博. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZKArchive.h"

@class ZKCDHeader;

@interface ZipArchive : ZKArchive{
    NSString *_savePath;
}

+ (ZipArchive *) process:(ZipArchive *) archiveFile withItems:(id)item usingResourceFork:(BOOL)flag withInvoker:(id)invoker andDelegate:(id)delegate;
+ (ZipArchive *) archiveWithArchivePath:(NSString *)archivePath;

- (NSInteger) inflateToDiskUsingResourceFork:(BOOL)flag;
- (NSInteger) inflateToDirectory:(NSString *)expansionDirectory usingResourceFork:(BOOL)rfFlag;
- (NSInteger) inflateFile:(ZKCDHeader *)cdHeader toDirectory:(NSString *)expansionDirectory;

- (NSInteger) deflateFiles:(NSArray *)paths relativeToPath:(NSString *)basePath usingResourceFork:(BOOL)flag;
- (NSInteger) deflateDirectory:(NSString *)dirPath relativeToPath:(NSString *)basePath usingResourceFork:(BOOL)flag;
- (NSInteger) deflateFile:(NSString *)path relativeToPath:(NSString *)basePath usingResourceFork:(BOOL)flag;

@property (assign) BOOL useZip64Extensions;

@end