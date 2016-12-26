//
//  DetailsSerialModel.h
//  SerialPLayer
//
//  Created by Vadim Denisuk on 13.09.16.
//  Copyright © 2016 Vadim Denisuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DetailsSerialModel : NSObject
@property (strong, nonatomic) NSString *NameSerial;
@property (strong, nonatomic) NSURL *posterSerialLarge;
@property (strong, nonatomic) NSURL *posterSerialNormal;
@property (strong, nonatomic) NSString *roles;
@property (strong, nonatomic) NSString *year;
@property (strong, nonatomic) NSString *counrty;
@property (strong, nonatomic) NSString *genre;
@property (strong, nonatomic) NSString *descriptionSerial;
@property (strong, nonatomic) NSArray *serialLinks;
@property (strong, nonatomic) NSArray *translateList;
@property (nonatomic,assign) BOOL favorite;

@end
