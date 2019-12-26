//
//  CommonHelper.h
//  iOSCommand
//
//  Created by 郑宗刚 on 2019/12/26.
//  Copyright © 2019 QDFish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Header.h"

NS_ASSUME_NONNULL_BEGIN

@interface CommonHelper : NSObject

+ (BOOL)string:(NSString *)str mathPattern:(NSString *)pattern;

+ (NSArray<NSString *> *)resultWithString:(NSString *)str pattern:(NSString *)pattern;
+ (NSArray<NSString *> *)resultWithString:(NSString *)str pattern:(NSString *)pattern trimmingBlank:(BOOL)needBlank;

@end

NS_ASSUME_NONNULL_END
