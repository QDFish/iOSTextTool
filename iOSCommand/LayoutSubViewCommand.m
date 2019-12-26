//
//  LayoutSubViewCommand.m
//  iOSCommand
//
//  Created by 郑宗刚 on 2019/12/26.
//  Copyright © 2019 QDFish. All rights reserved.
//

#import "LayoutSubViewCommand.h"
#import "CommonHelper.h"
#import "HBProperty.h"

@implementation LayoutSubViewCommand

- (NSString *__nullable)getClassNameWithSelections:(NSArray *)selectLines {
    NSString *firstLine = [selectLines firstObject];
    NSArray *results = [CommonHelper resultWithString:firstLine pattern:@"(?<=@interface)\\s*\\w+\\s*"];
    if (![results count]) {
        return nil;
    }
    
    return [results firstObject];
}

- (NSArray <HBProperty *> *)propertysWithSelections:(NSArray *)selectLines {
    NSMutableArray *arrs = [NSMutableArray array];
    for (NSString *line in selectLines) {
        NSArray *results = [CommonHelper resultWithString:line pattern:@"\\s*@property|\\s*\\(.*\\)\\s*|\\w+|\\s*\\*\\s*|\\w+"];
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
        NSArray *results = [CommonHelper resultWithString:line pattern:@"\\s*@implementation|\\s*\\w+\\s*"];
                
        if (!findImplementaion && [results count] < 2) {
            continue;
            
        } else if (!findImplementaion && [[results firstObject] isEqualToString:@"@implementation"] /*&& [results[1] isEqualToString:name]*/) {
            findImplementaion = YES;
            continue;
        }
        
        //        NSLog(@"result %@ line %@", results[0], line);
        
        results = [CommonHelper resultWithString:line pattern:@"\\s*@end\\s*"];
        if (findImplementaion && [results count] && [[results firstObject] isEqualToString:@"@end"]) {
            insertLine = i;
            break;
        }
    }
    
    return insertLine;
}

- (void)dealPropertys:(NSArray <HBProperty *> *)propertys allLines:(NSMutableArray *)lines withFirstPoint:(NSInteger)firstPoint {
    NSMutableArray *secondPart = [NSMutableArray array];
    NSMutableArray *firstPart = [NSMutableArray array];
    
    for (HBProperty *property in propertys) {
        NSString *content = [NSBundle mainBundle].infoDictionary[[NSString stringWithFormat:@"#%@#", property.type]];
        if (!content.length) {
            content = [NSBundle mainBundle].infoDictionary[@"#UIView#"];
        }
        
        if (content.length) {
                                    
            NSString *firstStr = [NSString stringWithFormat:@"\t[<#superView#> addSubview:self.%@];", property.name];
            [firstPart addObject:firstStr];
            
            content = [content stringByReplacingOccurrencesOfString:@"#name#" withString:[NSString stringWithFormat:@"_%@", property.name]];
            NSRange range = [content rangeOfString:@"\n" options:NSBackwardsSearch];
            content = [content stringByReplacingCharactersInRange:range withString:@""];
            range = [content rangeOfString:@"\n" options:0];
            content = [content stringByReplacingCharactersInRange:range withString:@""];
            
            NSArray *propertyLines = [content componentsSeparatedByString:@"\n"];
            NSMutableArray *newLines = [NSMutableArray arrayWithCapacity:propertyLines.count];
            [newLines addObject:@"- (#type# *)#name# {"];
            [newLines addObject:@"\tif (!_#name#) {"];
            for (NSString *line in propertyLines) {
                NSString *newLine = [@"\t\t" stringByAppendingString:line];
                [newLines addObject:newLine];
            }
            [newLines addObject:@"\t}"];
            [newLines addObject:@"\treturn _#name#;"];
            [newLines addObject:@"}"];
            
            content = [newLines componentsJoinedByString:@"\n"];
            content = [content stringByReplacingOccurrencesOfString:@"#name#" withString:property.name];
            content = [content stringByReplacingOccurrencesOfString:@"#type#" withString:property.type];
            content = [content stringByReplacingOccurrencesOfString:@"[#" withString:@"<#"];
            content = [content stringByReplacingOccurrencesOfString:@"#]" withString:@"#>"];
            
            newLines = [[content componentsSeparatedByString:@"\n"] mutableCopy];
            [secondPart addObjectsFromArray:newLines];
        }
    }
    
    [lines insertObjects:firstPart atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstPoint, firstPart.count)]];
    NSInteger secondPoint = [self insertPointWithLines:lines classname:nil];
    
    if (secondPoint != NSNotFound) {
        [lines insertObjects:secondPart atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(secondPoint, secondPart.count)]];
    }
}

- (NSInteger)insert:(NSMutableArray *)lines subviewInterface:(NSInteger)inserPoint {
    NSInteger initPoint = NSNotFound;
    BOOL find = NO;
    for (NSInteger i = 0; i < lines.count; i++) {
        NSString *line = lines[i];
                
        if (find && [CommonHelper string:line mathPattern:@"\\s*\\[\\s*.+\\s*addSubview.*"]) {
            initPoint = i + 1;
        } else if (!find && [[CommonHelper resultWithString:line pattern:@"\\s*-\\s*\\(\\s*void\\s*\\)\\s*initSubViews\\s*\\{\\s*"] count]) {
            find = YES;
        }
    }
    
    if (initPoint != NSNotFound) {
        return initPoint;
    }
    
    NSMutableArray *firstPart = [NSMutableArray array];
    [firstPart addObject:@"- (void)initSubViews {"];
    [firstPart addObject:@"}"];
        
    [lines insertObjects:firstPart atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(inserPoint, 2)]];
    
    return inserPoint + 1;
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
//    if (![className length]) {
//        XCFalied(@"classname requried");
//    }
    
    NSArray <HBProperty *> *propertys = [self propertysWithSelections:selectLines];
    if (![propertys count]) {
        XCFalied(@"it should have 1 propery at least");
    }
    
    NSInteger secondPoint = [self insertPointWithLines:lines classname:className];
    if (secondPoint == NSNotFound || secondPoint < 0) {
        XCFalied(@"can't find the @end");
    }
    
    NSInteger firstPoint = [self insert:lines subviewInterface:secondPoint];
    
    [self dealPropertys:propertys allLines:lines withFirstPoint:firstPoint];
    XCSuccess();
}

@end
