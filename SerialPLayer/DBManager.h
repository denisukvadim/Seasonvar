//
//  DBManager.h
//  SerialPLayer
//
//  Created by Vadim Denisuk on 30.08.16.
//  Copyright © 2016 Vadim Denisuk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDatabase.h>

@interface DBManager : NSObject

@property (nonatomic, strong) FMDatabase *db;


-(instancetype)initWithDatabaseFilename:(NSString *)dbFilename;

-(void)writeArraySerials:(NSMutableArray *)serialsArray;
- (NSString*) getLastModifiedDate;
- (void) updateLastModifiedDate:(NSString*) date;
-(NSMutableArray *)getArraySerials;
-(NSMutableArray *)getArrayFavoriteSerials;
-(BOOL)favoriteStatus:(NSString *)serialID;
-(BOOL)writeToDB:(NSString*)NameSerial WithLink:(NSString*)link WithId:(NSString*) idSer;
-(BOOL)delFavoriteFromDB:(NSString*) idSer;
-(NSString *)getTokenURlFromDB;
-(BOOL)setSettingToBD:(NSString *)tokenURL;
@end

