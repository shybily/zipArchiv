//
//  Images.m
//  betty
//
//  Created by 杨博 on 13-8-5.
//  Copyright (c) 2013年 杨博. All rights reserved.
//

#import "Images.h"

@implementation Images

/* our datasource object is just a filepath representation */
- (void)setPath:(NSString *)path
{
    if(_path != path)
    {
        _path = path;
        
    }
}

- (NSString *)getFileName{
    
    return [_path lastPathComponent];
}


/* required methods of the IKImageBrowserItem protocol */
#pragma mark -
#pragma mark item data source protocol

/* let the image browser knows we use a path representation */
- (NSString *)imageRepresentationType
{
	return IKImageBrowserPathRepresentationType;
}

/* give our representation to the image browser */
- (id)imageRepresentation
{
	return _path;
}

/* use the absolute filepath as identifier */
- (NSString *)imageUID
{
    return _path;
}

@end
