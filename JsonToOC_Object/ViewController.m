//
//  ViewController.m
//  JsonToOC_Object
//
//  Created by 杨肖宇 on 2018/7/2.
//  Copyright © 2018年 杨肖宇. All rights reserved.
//

#import "ViewController.h"
#import "NSAlert+Help.h"

@interface ViewController ()

/**
 .h文件的字符串
 */
@property (nonatomic, strong) NSMutableString *modelStr;
@property (nonatomic, strong) NSMutableArray *modelStrArr;

/**
 .m文件的字符串
 */
@property (nonatomic, strong) NSMutableString *mStr;
@property (nonatomic, strong) NSMutableArray *modelNameArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)chooseModelPathClicked:(id)sender {
    NSWindow* window = self.view.window;
    
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [panel setPrompt:@"选择"];
    [panel setMessage:@"选择一个路径"];
    
    [panel beginSheetModalForWindow:window completionHandler:^(NSInteger result){
        if (result == NSModalResponseOK) {
            NSURL*  theDoc = [[panel URLs] objectAtIndex:0];
            NSRange range = [theDoc.description rangeOfString:@"file://"];
            NSString *path = [theDoc.description substringFromIndex:(range.location + range.length)];
            self.modelPath.stringValue = [path stringByRemovingPercentEncoding];
            NSLog(@"%@", self.modelPath.stringValue);
        }
    }];
}

- (IBAction)createModelClicked:(id)sender {

    NSString *jsonString = [self.jsonData.documentView textStorage].string;
    if ([jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0){
        [NSAlert alertWithMessage:@"Json数据错误"];
        return;
    }
    
    NSDictionary *dict = [NSDictionary dictionary];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    id obj = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
    if ([obj isKindOfClass:[NSDictionary class]]){
        dict = obj;
    }else if ([obj isKindOfClass:[NSArray class]]){
        if (((NSArray *)obj).count > 0){
            dict = ((NSArray *)obj)[0];
        }else{
            [NSAlert alertWithMessage:@"Json数据错误"];
            return;
        }
    }else{
        [NSAlert alertWithMessage:@"Json数据错误"];
        return;
    }
    
    NSString *className = self.modelClassName.stringValue.length ? self.modelClassName.stringValue : @"RootModel";
    [self.modelStrArr removeAllObjects];
    [self.modelNameArr removeAllObjects];
    [self.modelNameArr addObject:className];
    [self.mStr setString:[NSString stringWithFormat:@"\n#import \"%@.h\"", className]];
    [self.modelStr setString:@"\n#import <Foundation/Foundation.h>\n"];
    
    [self createPropertyCodeWithDict:dict modelClassName:className];
    
    for (NSString *str in self.modelNameArr){
        [self.mStr appendFormat:@"\n\n@implementation %@\n\n@end\n", str];
    }
    for (NSString *str in self.modelStrArr) {
        [self.modelStr appendString:str];
        [self.modelStr appendString:@"\n\n\n"];
    }
    
    NSString *alertStr = @"";
    if ([self saveModelString:self.modelStr withModelName:[className stringByAppendingString:@".h"]]) {
        alertStr = [alertStr stringByAppendingFormat:@"%@.h文件生成成功\n", className];
    }else{
        alertStr = [alertStr stringByAppendingFormat:@"%@.h文件生成失败\n", className];
    }
    if ([self saveModelString:self.mStr withModelName:[className stringByAppendingString:@".m"]]) {
        alertStr = [alertStr stringByAppendingFormat:@"%@.m文件生成成功", className];
    }else{
        alertStr = [alertStr stringByAppendingFormat:@"%@.m文件生成失败", className];
    }
    [NSAlert alertWithMessage:alertStr];
}

- (void)createPropertyCodeWithDict:(NSDictionary *)dict modelClassName:(NSString *)modelClassName{
    
    NSMutableString *headerContentStrM = [NSMutableString string];
    NSString *preStr = [NSString stringWithFormat:@"\n@interface %@ : NSObject", modelClassName];
    [headerContentStrM appendFormat:@"\n%@\n",preStr];
    
    for (NSString *propertyName in dict){
        NSString *code;
        NSString *value = dict[propertyName];
        
        if ([value isKindOfClass:NSClassFromString(@"__NSCFBoolean")])
        {
            code = [NSString stringWithFormat:@"@property (nonatomic, assign) BOOL %@;",propertyName];
        }
        else if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:NSClassFromString(@"NSTaggedPointerString")])
        {
            code = [NSString stringWithFormat:@"@property (nonatomic, copy) NSString *%@;",propertyName];
        }
        else if ([value isKindOfClass:[NSNumber class]])
        {
            code = [NSString stringWithFormat:@"@property (nonatomic, strong) NSNumber *%@;",propertyName];
        }
        else if ([value isKindOfClass:[NSArray class]])
        {
            NSString *name = [[self.subModelPrefix.stringValue stringByAppendingString:[self uppercaseFirstChar:propertyName]] stringByAppendingString:@"Model"];
            code = [NSString stringWithFormat:@"@property (nonatomic, strong) NSArray<%@ *> *%@;",name ,propertyName];
            
            NSArray *arr = (NSArray *)dict[propertyName];
            if (arr.count > 0)
            {
                //如果是Foundation框架下的类型,比如NSArray下是{"name":"超重低音","gainArray":[6,8,7,4,0,-1,-5,1,2,-2],"equalizerEffect":2}，根本没有key,也就是根本不是字典，直接使用即可。
                if (![arr[0] isKindOfClass:[NSDictionary class]])
                {
                    code = [NSString stringWithFormat:@"@property (nonatomic, strong) NSArray *%@;", propertyName];
                }
                else
                {
                    //如果发现是数组的话，则试着去取第一个来产生一个Model
                    [self createPropertyCodeWithDict:arr[0] modelClassName:name];
                    if (![self.modelNameArr containsObject:name]) {
                        [self.modelNameArr addObject:name];
                    }
                }
            }
        }
        else if ([value isKindOfClass:[NSDictionary class]])
        {
            NSString *name = [[self.subModelPrefix.stringValue stringByAppendingString:[self uppercaseFirstChar:propertyName]] stringByAppendingString:@"Model"];
            
            code = [NSString stringWithFormat:@"@property (nonatomic, strong) %@ *%@;", name, propertyName];
            //如果发现是字典的话，则试着再次调用此方法来产生一个Model
            [self createPropertyCodeWithDict:dict[propertyName] modelClassName:name];
            if (![self.modelNameArr containsObject:name]) {
                [self.modelNameArr addObject:name];
            }
        }
        
        if (code != nil)
        {
            [headerContentStrM appendFormat:@"\n%@\n",code];
        }
    }
    [headerContentStrM appendFormat:@"\n@end"];
    if (![self.modelStrArr containsObject:headerContentStrM]) {
        [self.modelStrArr addObject:headerContentStrM];
    }
}

- (BOOL)saveModelString:(NSString *)modelString withModelName:(NSString *)modelName
{
    NSString *deskTopPath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = self.modelPath.stringValue.length ? self.modelPath.stringValue : deskTopPath;
    // 拼接文件完整目录
    NSString *dicPath = [path stringByAppendingPathComponent:modelName];
    // 初始化文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // 创建文件目录
    NSError *error = nil;
    [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    // 判断,如果文件是否存在
    if (![fileManager fileExistsAtPath:dicPath])
    {   // 文件不存在就创建文件
        BOOL createSuccess = [fileManager createFileAtPath:dicPath contents:nil attributes:nil];
        NSLog(@"%@\ndesktopPath==%@\ndicPath==%@\npath==%@\nError was code: %d - message: %s", createSuccess?@"yes":@"no", deskTopPath, dicPath, path, errno, strerror(errno));
    }
    // 写入数据到文件
    return [modelString writeToFile:dicPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (NSString *)uppercaseFirstChar:(NSString *)str{
    NSString *low = [str substringToIndex:1];
    return [[low capitalizedString] stringByAppendingString:[str substringFromIndex:1]];
}

- (NSMutableString *)modelStr{
    if (!_modelStr){
        _modelStr = [NSMutableString new];
    }
    return _modelStr;
}

- (NSMutableArray *)modelStrArr{
    if (!_modelStrArr){
        _modelStrArr = [NSMutableArray new];
    }
    return _modelStrArr;
}

- (NSMutableString *)mStr{
    if (!_mStr){
        _mStr = [NSMutableString new];
    }
    return _mStr;
}

- (NSMutableArray *)modelNameArr{
    if (!_modelNameArr){
        _modelNameArr = [NSMutableArray new];
    }
    return _modelNameArr;
}

@end
