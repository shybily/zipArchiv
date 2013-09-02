//
//  Images.h
//  betty
//
//  Created by 杨博 on 13-8-5.
//  Copyright (c) 2013年 杨博. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <Foundation/Foundation.h>

@interface Images : NSObject{
    NSURL *_path;
}

- (void) setPath:(NSURL *)path;
- (NSString *) getFileName;

@end
