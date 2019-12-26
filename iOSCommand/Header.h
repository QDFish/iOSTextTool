//
//  Header.h
//  iOSCommand
//
//  Created by 郑宗刚 on 2019/12/26.
//  Copyright © 2019 QDFish. All rights reserved.
//

#ifndef Header_h
#define Header_h

#define XCSuccess() completionHandler(nil)
#define XCFalied(msg) completionHandler([NSError errorWithDomain:msg code:-1 userInfo:nil]); \
                      return

#endif /* Header_h */
