//
//  InitSubviewCommand.m
//  iOSCommand
//
//  Created by 郑宗刚 on 2019/12/26.
//  Copyright © 2019 QDFish. All rights reserved.
//

#import "InitSubviewCommand.h"
#import "Header.h"
#import "HBProperty.h"
#import "CommonHelper.h"

@implementation InitSubviewCommand

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler {
    NSMutableArray <XCSourceTextRange *> *selections = invocation.buffer.selections;
    NSMutableArray *lines = invocation.buffer.lines;

    if (![selections count]) {
        XCFalied(@"selection is invalid");
    }
        
    XCSourceTextRange *selection = [selections firstObject];
    NSMutableArray *selectLines = [NSMutableArray array];
    [selectLines addObjectsFromArray:[lines objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(selection.start.line, selection.end.line - selection.start.line + 1)]]];
    
    
    HBProperty *property = [self propertyWithSelections:selectLines];
    if (!property) {
        XCFalied(@"it should have type and name");
    }
    
    [self dealProperty:property allLines:lines withFirstPoint:selection.start.line];
    XCSuccess();
}

- (void)dealProperty:(HBProperty *)property allLines:(NSMutableArray *)lines withFirstPoint:(NSInteger)firstPoint {
    NSMutableArray *secondPart = [NSMutableArray array];
    NSString *content = [NSBundle mainBundle].infoDictionary[[NSString stringWithFormat:@"#%@#", property.type]];
    if (!content.length) {
        content = [NSBundle mainBundle].infoDictionary[@"#UIView#"];
    }
    
    if (content.length) {
        NSRange range = [content rangeOfString:@"\n" options:NSBackwardsSearch];
        content = [content stringByReplacingCharactersInRange:range withString:@""];
        range = [content rangeOfString:@"\n" options:0];
        content = [content stringByReplacingCharactersInRange:range withString:@""];
        content = [@"#type# *" stringByAppendingString:content];
        
        NSArray *propertyLines = [content componentsSeparatedByString:@"\n"];
        NSMutableArray *newLines = [NSMutableArray arrayWithCapacity:propertyLines.count];
        for (NSString *line in propertyLines) {
            NSString *newLine = [property.space stringByAppendingString:line];
            [newLines addObject:newLine];
        }
        [newLines addObject:[property.space stringByAppendingFormat:@"[<#superView#> addSubview:self.%@];", property.name]];
        
        content = [newLines componentsJoinedByString:@"\n"];
        content = [content stringByReplacingOccurrencesOfString:@"#name#" withString:property.name];
        content = [content stringByReplacingOccurrencesOfString:@"#type#" withString:property.type];
        content = [content stringByReplacingOccurrencesOfString:@"[#" withString:@"<#"];
        content = [content stringByReplacingOccurrencesOfString:@"#]" withString:@"#>"];
        
        newLines = [[content componentsSeparatedByString:@"\n"] mutableCopy];
        [secondPart addObjectsFromArray:newLines];
    }
    
    if (firstPoint < lines.count) {
        [lines removeObjectAtIndex:firstPoint];
        [lines insertObjects:secondPart atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstPoint, secondPart.count)]];
    }
}

- (HBProperty *)propertyWithSelections:(NSArray *)selectLines {
    NSString *line = [selectLines firstObject];
    NSArray *results = [CommonHelper resultWithString:line pattern:@"^\\s+|\\w+|\\s*\\*\\s*|\\w+$" trimmingBlank:NO];
    if ([results count] >= 3) {
        NSString *firstPart = results[0];
        NSString *space = @"";
        NSString *type;
        if ([CommonHelper string:firstPart mathPattern:@"^\\s+$"]) {
            space = firstPart;
            type = results[1];
        } else {
            type = results[0];
        }
        HBPropertyInit1(property, [results lastObject], type, space);
        NSLog(@"type %@ name %@ space%@|", type, results.lastObject, space);
        return property;
    }
    
    return nil;
}


@end
