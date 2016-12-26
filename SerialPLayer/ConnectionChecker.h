//
//  ConnectionChecker.h
//  SerialPLayer
//
//  Created by Developer Eventsoft on 11.12.16.
//  Copyright © 2016 Vadim Denisuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConnectionChecker : NSObject


//+ (id)sharedInstance;
- (BOOL)checkInternetConnection;
@end
