//
//  ViewController.h
//  JsonToOC_Object
//
//  Created by 杨肖宇 on 2018/7/2.
//  Copyright © 2018年 杨肖宇. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (weak) IBOutlet NSTextField *modelClassName;
@property (weak) IBOutlet NSTextField *subModelPrefix;
@property (weak) IBOutlet NSScrollView *jsonData;
@property (weak) IBOutlet NSTextField *modelPath;

@end

