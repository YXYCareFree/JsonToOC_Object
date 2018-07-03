//
//  NSAlert+Help.h
//  jcBiu
//
//  Created by 杨肖宇 on 2018/6/29.
//  Copyright © 2018年 jccf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSAlert (Help)

+ (void)alertWithMessage:(NSString *)msg inWindow:(NSWindow *)window;

+ (void)alertWithMessage:(NSString *)msg;

@end
