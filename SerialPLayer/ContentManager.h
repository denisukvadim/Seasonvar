//
//  ContentManager.h
//  SerialPLayer
//
//  Created by Vadim Denisuk on 07.09.16.
//  Copyright © 2016 Vadim Denisuk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBManager.h"
#import "DetailsSerialModel.h"

@interface ContentManager : NSObject
@property (nonatomic, strong) DBManager *dbManager;
@property (nonatomic, strong) NSString *keyTokken;

typedef NS_ENUM(NSUInteger, ItemMenu) {
    All = 0,
    News = 1,
    Favorite = 2
};

+ (id)sharedInstance;

- (NSMutableArray*) getArraySerials:(ItemMenu)itemMenu;
- (void) addSerialsToDB:(NSMutableArray*)serialsArray;

- (NSString*) getLastModifiedDate;
- (void) updateLastModifiedDate:(NSString*) date;
- (DetailsSerialModel*) getDetailsSerialWithLink:(NSString*)link WithId:(NSString*) idSer;
-(NSMutableArray *)getDovloadTask:(NSString *)serialID translate:(NSString *)translate;
-(BOOL)writeToFavorite:(NSString*)NameSerial WithLink:(NSString*)link WithId:(NSString*) idSer;
-(BOOL)delFromFavorite:(NSString*) idSer;
-(void)setSetting;
-(NSString *)requestTokken;
@end
