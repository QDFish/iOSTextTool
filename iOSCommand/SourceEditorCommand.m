//
//  SourceEditorCommand.m
//  iOSCommand
//
//  Created by QDFish on 2019/12/6.
//  Copyright © 2019 QDFish. All rights reserved.
//

#import "SourceEditorCommand.h"

#define HBPropertyInit(_var, _name, _type) \
HBProperty *_var = [HBProperty new]; \
_var.type = _type; \
_var.name = _name; \

#define XCSuccess() completionHandler(nil)
#define XCFalied(msg) completionHandler([NSError errorWithDomain:msg code:-1 userInfo:nil]); \
                      return

@interface HBProperty : NSObject

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *name;

@end

@implementation HBProperty

@end

@implementation SourceEditorCommand

- (NSString *__nullable)getClassNameWithSelections:(NSArray *)selectLines {
    NSString *firstLine = [selectLines firstObject];
    NSArray *results = [self resultWithString:firstLine pattern:@"(?<=@interface)\\s*\\w+\\s*"];
    if (![results count]) {
        return nil;
    }
    
    return [results firstObject];
}

- (NSArray <HBProperty *> *)propertysWithSelections:(NSArray *)selectLines {
    NSMutableArray *arrs = [NSMutableArray array];
    for (NSString *line in selectLines) {
        NSArray *results = [self resultWithString:line pattern:@"\\s*@property|\\s*\\(.*\\)\\s*|\\w+|\\s*\\*\\s*|\\w+"];
        if ([results count] < 4) {
            continue;
        }
        if ([[results firstObject] isEqualToString:@"@property"]) {
            NSString *name = results.lastObject;
            if (![results[results.count - 2] isEqualToString:@"*"]) {
                continue;
            }
            NSString *type = results[results.count - 3];
            HBPropertyInit(item, name, type);
            [arrs addObject:item];
            NSLog(@"type=%@, name %@", type, name);
        }
    }
    return [arrs copy];
}

- (NSInteger)insertPointWithLines:(NSMutableArray *)lines classname:(NSString *)name {
    BOOL findImplementaion = NO;
    NSInteger insertLine = NSNotFound;
    for (NSInteger i = 0; i < lines.count; i++) {
        NSString *line = lines[i];
        NSArray *results = [self resultWithString:line pattern:@"\\s*@implementation|\\s*\\w+\\s*"];
                
        if (!findImplementaion && [results count] < 2) {
            continue;
            
        } else if (!findImplementaion && [[results firstObject] isEqualToString:@"@implementation"] && [results[1] isEqualToString:name]) {
            findImplementaion = YES;
            continue;
        }
        
        //        NSLog(@"result %@ line %@", results[0], line);
        
        results = [self resultWithString:line pattern:@"\\s*@end\\s*"];
        if (findImplementaion && [results count] && [[results firstObject] isEqualToString:@"@end"]) {
            insertLine = i;
            break;
        }
    }
    
    return insertLine;
}

- (NSArray *)dealPropertys:(NSArray <HBProperty *> *)propertys {
    NSMutableArray *allNewLines = [NSMutableArray array];
    
    NSMutableArray *firstPart = [NSMutableArray array];
    [firstPart addObject:@"- (void)initSubViews {"];
    NSMutableArray *secondPart = [NSMutableArray array];
    for (HBProperty *property in propertys) {
        NSString *content = [NSBundle mainBundle].infoDictionary[[NSString stringWithFormat:@"#%@#", property.type]];
        if (content.length) {
            NSString *firstStr = [NSString stringWithFormat:@"\t[<#superView#> addSubView:self.%@];", property.name];
            [firstPart addObject:firstStr];
            
            content = [content stringByReplacingOccurrencesOfString:@"#type#" withString:property.type];
            content = [content stringByReplacingOccurrencesOfString:@"#name#" withString:property.name];
            content = [content stringByReplacingOccurrencesOfString:@"[#" withString:@"<#"];
            content = [content stringByReplacingOccurrencesOfString:@"#]" withString:@"#>"];
            NSRange range = [content rangeOfString:@"\n" options:NSBackwardsSearch];
            content = [content stringByReplacingCharactersInRange:range withString:@""];
            NSArray *newlines = [content componentsSeparatedByString:@"\n"];
            [secondPart addObjectsFromArray:newlines];
        }
    }
    
    [firstPart addObject:@"}"];
    [allNewLines addObjectsFromArray:firstPart];
    [allNewLines addObjectsFromArray:secondPart];
    return [allNewLines copy];
}

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler {
    
    NSMutableArray <XCSourceTextRange *> *selections = invocation.buffer.selections;
    NSMutableArray *lines = invocation.buffer.lines;

    if (![selections count]) {
        XCFalied(@"selection is invalid");
    }
        
    XCSourceTextRange *selection = [selections firstObject];
    NSMutableArray *selectLines = [NSMutableArray array];
    [selectLines addObjectsFromArray:[lines objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(selection.start.line, selection.end.line - selection.start.line + 1)]]];
    
    NSString *className = [self getClassNameWithSelections:selectLines];
    NSLog(@"classname %@", className);
    if (![className length]) {
        XCFalied(@"classname requried");
    }
    
    NSArray <HBProperty *> *propertys = [self propertysWithSelections:selectLines];
    if (![propertys count]) {
        XCFalied(@"it should have 1 propery at least");
    }
    
    
    NSInteger insertLine = [self insertPointWithLines:lines classname:className];
    if (insertLine == NSNotFound || insertLine < 0) {
        XCFalied(@"can't find the @end");
    }
    
    NSArray *allNewLines = [self dealPropertys:propertys];
    [lines insertObjects:allNewLines atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertLine, allNewLines.count)]];
    XCSuccess();
}


- (NSArray<NSString *> *)resultWithString:(NSString *)str pattern:(NSString *)pattern {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSArray<NSTextCheckingResult *> *rowResult = [regex matchesInString:str options:0 range:NSMakeRange(0, str.length)];
    NSMutableArray *results = [NSMutableArray array];
    if (rowResult) {
        for (int i = 0; i < rowResult.count; i++) {
            NSTextCheckingResult *res = rowResult[i];
            NSString *reStr = [str substringWithRange:res.range];
            reStr = [reStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [results addObject:reStr];
        }
    } else {
        NSLog(@"error == %@",error.description);
    }
    
    return results;
}

@end
