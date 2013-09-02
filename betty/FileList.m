//
//  FileList.m
//  ZipArchive
//
//  Created by 杨博 on 13-8-30.
//  Copyright (c) 2013年 杨博. All rights reserved.
//

#import "FileList.h"

@implementation FileList

- (void)addFullPath:(NSURL *)fullPath withNewName:(NSString *)newName{
    _fullPath = fullPath;
    _newName = newName;
}

- (NSURL *)getFullPath{
    return _fullPath;
}

- (NSString *)getNewName{
    return _newName;
}



@end
