//
//  CommonHelper.m
//  iOSCommand
//
//  Created by 郑宗刚 on 2019/12/26.
//  Copyright © 2019 QDFish. All rights reserved.
//

#import "CommonHelper.h"

@implementation CommonHelper

+ (BOOL)string:(NSString *)str mathPattern:(NSString *)pattern {
    return [[self resultWithString:str pattern:pattern] count];
}

+ (NSArray<NSString *> *)resultWithString:(NSString *)str pattern:(NSString *)pattern {
    return [self resultWithString:str pattern:pattern trimmingBlank:YES];
}
 
+ (NSArray<NSString *> *)resultWithString:(NSString *)str pattern:(NSString *)pattern trimmingBlank:(BOOL)trimmingBlank {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSArray<NSTextCheckingResult *> *rowResult = [regex matchesInString:str options:0 range:NSMakeRange(0, str.length)];
    NSMutableArray *results = [NSMutableArray array];
    if (rowResult) {
        for (int i = 0; i < rowResult.count; i++) {
            NSTextCheckingResult *res = rowResult[i];
            NSString *reStr = [str substringWithRange:res.range];
            if (trimmingBlank) {
                reStr = [reStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
            [results addObject:reStr];
        }
    } else {
        NSLog(@"error == %@",error.description);
    }
    
    return results;
}



@end
