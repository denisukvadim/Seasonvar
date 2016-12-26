//
//  SerialModel.h
//  SerialPLayer
//
//  Created by Vadim Denisuk on 07.09.16.
//  Copyright © 2016 Vadim Denisuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SerialModel : NSObject
@property (strong, nonatomic) NSString *Id;
@property (strong, nonatomic) NSString *Name;
@property (strong, nonatomic) NSString *Url;
@property (strong, nonatomic) NSURL *ImageURL;
@end
