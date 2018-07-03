//
//  NSAlert+Help.m
//  jcBiu
//
//  Created by 杨肖宇 on 2018/6/29.
//  Copyright © 2018年 jccf. All rights reserved.
//

#import "NSAlert+Help.h"

@implementation NSAlert (Help)

+ (void)alertWithMessage:(NSString *)msg{
    [NSAlert alertWithMessage:msg inWindow:[NSApplication sharedApplication].keyWindow];
}

+ (void)alertWithMessage:(NSString *)msg inWindow:(NSWindow *)window{
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"提示";
    [alert setInformativeText:msg];
    [alert beginSheetModalForWindow:window completionHandler:nil];
}

@end
