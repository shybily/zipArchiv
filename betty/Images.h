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
    NSString *_path;
}

- (void) setPath:(NSString *)path;
- (NSString *) getFileName;

@end
