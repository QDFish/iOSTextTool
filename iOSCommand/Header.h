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

#define HBPropertyInit(_var, _name, _type) \
HBProperty *_var = [HBProperty new]; \
_var.type = _type; \
_var.name = _name; \

#define HBPropertyInit1(_var, _name, _type, _space) \
HBProperty *_var = [HBProperty new]; \
_var.type = _type; \
_var.name = _name; \
_var.space = _space;


#endif /* Header_h */
