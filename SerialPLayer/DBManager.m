//
//  DBManager.m
//  SerialPLayer
//
//  Created by Vadim Denisuk on 30.08.16.
//  Copyright © 2016 Vadim Denisuk. All rights reserved.
//

#import "DBManager.h"
#import <sqlite3.h>
#import <AFNetworking/AFNetworking.h>

@interface DBManager()
@property (nonatomic, strong) NSString *documentsDirectory;

@property (nonatomic, strong) NSString *databaseFilename;
@property (nonatomic, strong) NSMutableArray *dataFromDB;

@end
@implementation DBManager

#pragma mark - Initialization

-(instancetype)initWithDatabaseFilename:(NSString *)dbFilename{
    self = [super init];
    if (self) {
        NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.documentsDirectory = [paths objectAtIndex:0];
        self.databaseFilename = dbFilename;
        NSString *dbPath = [self.documentsDirectory stringByAppendingPathComponent:@"SeasonvarBase.db"];
        [self copyDatabaseIntoDocumentsDirectory];
        self.db = [FMDatabase databaseWithPath:dbPath];
    }
    return self;
}


#pragma mark - API database
-(void)writeArraySerials:(NSMutableArray *)serialsArray
{
//    self.db.traceExecution = true; //выводит подробный лог запросов в консоль
//    [self.db open];
//
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsPath = [paths objectAtIndex:0];
    NSString *dbPath = [docsPath stringByAppendingPathComponent:@"SeasonvarBase.db"];
    FMDatabase *database;
    database = [FMDatabase databaseWithPath:dbPath];
    database.traceExecution = false; //выводит подробный лог запросов в консоль
    [database open];
    BOOL success =  [database executeUpdate:@"DELETE FROM allserials"];
    if (success)
    {
        [database open];
        int i;
        for(i = 0; i< [serialsArray count]; i++)
        {
            [database executeUpdate:@"INSERT INTO allserials (id, url, name) VALUES (?, ?, ?)",
             [[serialsArray objectAtIndex:i] objectForKey:@"Id"],
             [[serialsArray objectAtIndex:i] objectForKey:@"Url"],
             [[serialsArray objectAtIndex:i] objectForKey:@"Name"]];
        }
    }
    [database close];
}

- (NSString*) getLastModifiedDate{
    NSString *lastUpdate = [[NSString alloc] init];
    FMResultSet *s = [self.db executeQuery:@"select * from settings"];
    while ([s next]) {
        lastUpdate = [s stringForColumn:@"lastUpdate"];
    }
    [self.db close];
    return lastUpdate;
}

- (void) updateLastModifiedDate:(NSString*) updateData{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:@"SeasonvarBase.db"];
    
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    [db open];
    [db executeUpdate:@"UPDATE settings SET lastUpdate = ? WHERE id = ?",updateData ,@"1"];
    [db close];
}
-(BOOL)favoriteStatus:(NSString *)serialID
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:@"SeasonvarBase.db"];
    
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM favorite WHERE serialId = ?",serialID];

    NSString *lastUpdate = [[NSString alloc] init];
    while ([results next]) {
        lastUpdate = [results stringForColumn:@"serialId"];
    }
    [self.db close];

    BOOL status;
    if ( lastUpdate.length > 0)
    {
        status = YES;
    }
    else
    {
        status = NO;
    }
     [db close];
    return status;
}
-(BOOL)writeToDB:(NSString*)NameSerial WithLink:(NSString*)link WithId:(NSString*) idSer
{
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsPath = [paths objectAtIndex:0];
    NSString *dbPath = [docsPath stringByAppendingPathComponent:@"SeasonvarBase.db"];
    FMDatabase *database;
    database = [FMDatabase databaseWithPath:dbPath];
    database.traceExecution = false; //выводит подробный лог запросов в консоль
    [database open];
    [database executeUpdate:@"INSERT INTO favorite (serialId, serialName, serialUrl) VALUES (?, ?, ?)",
     idSer, NameSerial, link];
    [database close];
    
    return [self favoriteStatus:idSer];
}
-(BOOL)delFavoriteFromDB:(NSString*) idSer
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:@"SeasonvarBase.db"];
        
        FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
        [db open];
        [db executeUpdate:@"DELETE FROM favorite WHERE serialId = ?", idSer];
        //SELECT name FROM sqlite_master WHERE type='table' AND name='table_name';
        [db close];
        return ![self favoriteStatus:idSer];
    }
-(NSMutableArray *)getArrayFavoriteSerials
{
    _dataFromDB = [[NSMutableArray alloc] init];
    
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsPath = [paths objectAtIndex:0];
    NSString *dbPath = [docsPath stringByAppendingPathComponent:@"SeasonvarBase.db"];
    FMDatabase *database;
    database = [FMDatabase databaseWithPath:dbPath];
    database.traceExecution = true; //выводит подробный лог запросов в консоль
    [database open];
    
    FMResultSet *results = [database executeQuery:@"select * from favorite"];
    while([results next]) {
        //[myDictionary removeAllObjects];
        NSMutableDictionary *myDictionary = [[NSMutableDictionary alloc] init];
        [myDictionary setObject:[results stringForColumn:@"serialId"] forKey:@"Id"];
        [myDictionary setObject:[results stringForColumn:@"serialName"] forKey:@"Name"];
        [myDictionary setObject:[results stringForColumn:@"serialUrl"] forKey:@"Url"];
        [_dataFromDB addObject:myDictionary];
    }
    [database close];
    return _dataFromDB;
}
-(BOOL)setSettingToBD:(NSString *)tokenURL
{

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:@"SeasonvarBase.db"];
    
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    [db open];
    [db executeUpdate:@"UPDATE settings SET token = ? WHERE id = ?",tokenURL ,@"1"];
    [db close];
    return YES;
}
-(NSString *)getTokenURlFromDB
{
    NSString *tokenURL = [[NSString alloc] init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:@"SeasonvarBase.db"];
    
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    [db open];
    FMResultSet *s = [db executeQuery:@"select * from settings"];
    while ([s next]) {
        tokenURL = [s stringForColumn:@"token"];
    }
    [db close];
    return tokenURL;
}

-(NSMutableArray *)getArraySerials
{
    _dataFromDB = [[NSMutableArray alloc] init];
    
    [self.db  open];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    //id response;
    __block NSMutableArray *contentSerials = [[NSMutableArray alloc] init];
    [manager.requestSerializer setValue:[self getLastModifiedDate] forHTTPHeaderField:@"If-Modified-Since"];
    [manager GET:@"http://seasonvarhd.azureedge.net/seasonvarhd/serials.json" parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        NSString *updateData = [[NSString alloc] init];
        if ([httpResponse respondsToSelector:@selector(allHeaderFields)]) {
            NSDictionary *dictionary = [httpResponse allHeaderFields];
            updateData = [dictionary objectForKey:@"Last-Modified"];
        }
        NSInteger statusCode = [response statusCode];
        if(statusCode ==200)
        {
            [contentSerials setArray:responseObject];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                static dispatch_once_t task;
                dispatch_once(&task, ^{
                    [self writeArraySerials:responseObject];
                    [self updateLastModifiedDate:updateData];
                    //[self loadItems];
                });
            });
            dispatch_semaphore_signal(semaphore);
        }
        
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)operation.response;
        NSInteger statusCode = [response statusCode];
        if(statusCode ==304)
        {
            [contentSerials setArray:[self loadItems]];
        }
        NSLog(@"Error: %@", error);
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return contentSerials;
}
- (NSMutableArray *)loadItems
{
    [_dataFromDB removeAllObjects];
    
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsPath = [paths objectAtIndex:0];
    NSString *dbPath = [docsPath stringByAppendingPathComponent:@"SeasonvarBase.db"];
    FMDatabase *database;
    database = [FMDatabase databaseWithPath:dbPath];
    database.traceExecution = true; //выводит подробный лог запросов в консоль
    [database open];
    
    FMResultSet *results = [database executeQuery:@"select * from allserials ORDER BY NAME"];
    while([results next]) {
        //[myDictionary removeAllObjects];
        NSMutableDictionary *myDictionary = [[NSMutableDictionary alloc] init];
        [myDictionary setObject:[results stringForColumn:@"id"] forKey:@"Id"];
        [myDictionary setObject:[results stringForColumn:@"name"] forKey:@"Name"];
        [myDictionary setObject:[results stringForColumn:@"url"] forKey:@"Url"];
        [_dataFromDB addObject:myDictionary];
    }
    [database close];
    return _dataFromDB;
}

#pragma mark - Private method implementation

-(void)copyDatabaseIntoDocumentsDirectory{
    // Check if the database file exists in the documents directory.
    NSString *destinationPath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
    if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
        // The database file does not exist in the documents directory, so copy it from the main bundle now.
        NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.databaseFilename];
        NSError *error;
        [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error];
        
        // Check if any error occurred during copying and display it.
        if (error != nil) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }
}



@end
