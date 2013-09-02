//
//  FileList.h
//  ZipArchive
//
//  Created by 杨博 on 13-8-30.
//  Copyright (c) 2013年 杨博. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileList : NSObject{
    NSURL *_fullPath;
    NSString *_newName;
}

- (void)addFullPath:(NSURL *)fullPath withNewName:(NSString *)newName;

- (NSURL *)getFullPath;
- (NSString *)getNewName;

@end
