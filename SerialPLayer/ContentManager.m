//
//  ContentManager.m
//  SerialPLayer
//
//  Created by Vadim Denisuk on 07.09.16.
//  Copyright © 2016 Vadim Denisuk. All rights reserved.
//

#import "ContentManager.h"
#import "XMLParser.h"
#import "SerialModel.h"
#import <CommonCrypto/CommonDigest.h>
#import <AFNetworking/AFNetworking.h>

@implementation ContentManager

#pragma mark - init methods
+ (id)sharedInstance
{
    static ContentManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ContentManager alloc] init];
        
    });
    return sharedInstance;
}

-(id)init{
    self = [super init];
    if (self) {
        self.dbManager = [[DBManager alloc] initWithDatabaseFilename:@"SeasonvarBase.db"];
    }
    return self;
}

-(NSString *)getTokenUrl
{
    NSString *urlList = [[NSString alloc] init];
    urlList =@"https://seasonvarhd.blob.core.windows.net/seasonvarhd/settings.json";
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.completionQueue =dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSString *result = @"http://seasonvar.ru/serial-13097-Po_sezonu_Videodajdzhest_Seasonvar-2-season.html";
    
    
    [manager GET:urlList parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            result = [responseObject objectForKey:@"TokenUrl"];
            dispatch_semaphore_signal(semaphore);
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)operation.response;
            NSInteger statusCode = [response statusCode];
            NSLog(@"Error code is %ld", (long)statusCode);
            dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return result;
}
-(void)setSetting
{
    NSString *urlTooken = [self getTokenUrl];
    [self.dbManager setSettingToBD:urlTooken];
}
#pragma mark - api methods
- (NSMutableArray*) getArraySerials:(ItemMenu)itemMenu{
    NSMutableArray *result=[NSMutableArray new];
    
    @try {
        switch (itemMenu) {
            case All:
                result = [self getAllSerials];
                break;
            case News:
                result = [self getNewSerials];
                break;
            case Favorite:
                result = [self getFavoriteSerials];
            default:
                break;
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
    }
    
    return result;
}

- (DetailsSerialModel*) getDetailsSerialWithLink:(NSString*)link WithId:(NSString*) idSer{
    DetailsSerialModel *model = [[DetailsSerialModel alloc] init];
    NSMutableDictionary *detailsList = [self GetInfoSerials:link];
    if (detailsList != nil)
    {
    model.NameSerial = [detailsList objectForKey:@"Name"];
    model.posterSerialLarge = [self getLargeImageLinkWithSerailId:idSer];
    model.posterSerialNormal = [self getImageLinkWithSerailId:idSer];
    model.roles = [detailsList objectForKey:@"Roles"];
    model.year = [detailsList objectForKey:@"Year"];
    model.counrty = [detailsList objectForKey:@"Country"];
    model.genre = [detailsList objectForKey:@"Genre"];
    model.descriptionSerial = [detailsList objectForKey:@"Description"];
    model.serialLinks = [detailsList objectForKey:@"SeasonLinks"];
    model.translateList = [detailsList objectForKey:@"PostScorings"];
    model.favorite = [self.dbManager favoriteStatus:idSer];
    }
    return model;
}
-(BOOL)writeToFavorite:(NSString *)NameSerial WithLink:(NSString *)link WithId:(NSString *)idSer
    {
        BOOL statusWrite = [self.dbManager writeToDB:NameSerial WithLink:link WithId:idSer];
        return statusWrite;
    }
-(BOOL)delFromFavorite:(NSString*) idSer
    {
       BOOL statusDelete = [self.dbManager delFavoriteFromDB:idSer];
        return statusDelete;
    }
-(NSMutableArray *)getDovloadTask:(NSString *)serialID translate:(NSString *)translate
{
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    manager.completionQueue =dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSMutableArray *playListSerialList = [[NSMutableArray alloc] init];
    NSURL *URL = [NSURL URLWithString:[self.dbManager getTokenURlFromDB]];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        NSString* content = [NSString stringWithContentsOfURL:filePath
                                                     encoding:NSUTF8StringEncoding
                                                        error:NULL];
        [[NSFileManager defaultManager] removeItemAtURL:filePath error:&error];
        NSURL *urlPlayList = [self getSecureKey:(content) serialId:serialID serialTranslate:translate];
        playListSerialList = [self getSerialVideoLink:urlPlayList];
        dispatch_semaphore_signal(semaphore);
        
    }];
    [downloadTask resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return playListSerialList;
    
}
-(NSString *)requestTokken
{
    self.keyTokken = [[NSString alloc] init];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    manager.completionQueue =dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSString *key = [[NSString alloc] init];
    NSURL *URL = [NSURL URLWithString:[self.dbManager getTokenURlFromDB]];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        NSString* content = [NSString stringWithContentsOfURL:filePath
                                                     encoding:NSUTF8StringEncoding
                                                        error:NULL];
        
        NSURL *listURL = [[NSURL alloc] init];
        NSUInteger characterCount = [[content componentsSeparatedByCharactersInSet:
                                      [NSCharacterSet newlineCharacterSet]] count];
        NSLog(@"Count %lu",(unsigned long)characterCount);
        NSMutableArray * fileLines = [[NSMutableArray alloc] initWithArray:[content componentsSeparatedByString:@"\n"] copyItems: YES];
        for(int i=0; i<fileLines.count; i++)
        {
            if ([[fileLines objectAtIndex:i] containsString:@"secureMark"]) {
                
                key = [[[fileLines objectAtIndex:i] componentsSeparatedByString:@"\""] objectAtIndex:1];
                NSLog(@"string contain bla %i, %@", i, key);
                self.keyTokken = key;
                break;
            } else {
                //NSLog(@"string does not contains bla!");
            }
        }        [[NSFileManager defaultManager] removeItemAtURL:filePath error:&error];

        dispatch_semaphore_signal(semaphore);
        
    }];
    [downloadTask resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    return self.keyTokken;
}
- (NSString *) md5:(NSString *) input
{
    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    return  output;
}
-(NSMutableDictionary *)GetInfoSerials:(NSString *)linkUrl
{
    NSString *urlList = [[NSString alloc] init];
    urlList =@"http://seasonvarhd.azureedge.net/seasonvarhd/";
    urlList = [urlList stringByAppendingString:[self md5:linkUrl]];
    urlList = [urlList stringByAppendingString:@".json"];
    

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.completionQueue =dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    
    
    [manager GET:urlList parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        result =responseObject;
        dispatch_semaphore_signal(semaphore);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)operation.response;
        NSInteger statusCode = [response statusCode];
        if(statusCode == 404)
        {
            NSDictionary *params = @{@"Url": linkUrl};
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            
            [manager POST:@"http://seasonvarhd.azurewebsites.net/api/Serial" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                result =responseObject;
                dispatch_semaphore_signal(semaphore);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                dispatch_semaphore_signal(semaphore);
            }];
        }
        else
        {
           dispatch_semaphore_signal(semaphore);
        }
    }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return result;
}

#pragma mark getSecureKey
-(NSURL *)getSecureKey:(NSString *)content serialId:(NSString *)serialID serialTranslate:(NSString *)translate
{
    NSURL *listURL = [[NSURL alloc] init];
    NSUInteger characterCount = [[content componentsSeparatedByCharactersInSet:
                                  [NSCharacterSet newlineCharacterSet]] count];
    NSLog(@"Count %lu",(unsigned long)characterCount);
    NSMutableArray * fileLines = [[NSMutableArray alloc] initWithArray:[content componentsSeparatedByString:@"\n"] copyItems: YES];
    for(int i=0; i<fileLines.count; i++)
    {
        if ([[fileLines objectAtIndex:i] containsString:@"secureMark"]) {
            
            NSString * key = [[[fileLines objectAtIndex:i] componentsSeparatedByString:@"\""] objectAtIndex:1];
            NSLog(@"string contain bla %i, %@", i, key);
            NSString *urlList = [[NSString alloc] init];
            urlList =@"http://seasonvar.ru/playls2/";
            urlList = [urlList stringByAppendingString:key];
            urlList = [urlList stringByAppendingString:@"8/trans"];
            if([translate isEqualToString:@"Стандартный"])
            {
                urlList = [urlList stringByAppendingString:@""];
            }
            else
            {
                urlList = [urlList stringByAppendingString:translate];
            }
            
            urlList = [urlList stringByAppendingString:@"/"];
            urlList = [urlList stringByAppendingString:serialID];
            urlList = [urlList stringByAppendingString:@"/list.xml"];
            //listURL = [[NSURL alloc] initWithString:urlList];
            listURL = [NSURL URLWithString:[urlList stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            break;
        } else {
            //NSLog(@"string does not contains bla!");
        }
    }
    return listURL;
}
-(NSMutableArray *)getSerialVideoLink:(NSURL *)listURL{
    
    NSArray *videoURLLink = [NSArray array];
    NSError *error;
    NSMutableArray *playListArray = [NSMutableArray array];
    NSURLRequest *urlMainRequest = [NSURLRequest requestWithURL:listURL
                                                    cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                timeoutInterval:30];
    NSData *urlMainData;
    NSURLResponse *responseMain;
    urlMainData = [NSURLConnection sendSynchronousRequest:urlMainRequest
                                        returningResponse:&responseMain
                                                    error:&error];
    videoURLLink = [NSJSONSerialization JSONObjectWithData:urlMainData options:0 error:&error];
    for (int i=0; i < [videoURLLink count]; i++) {
        NSDictionary *dictionary = videoURLLink;
        for(int j=0; j<[[dictionary objectForKey:@"playlist"] count]; j++)
        {
            if([[[dictionary objectForKey:@"playlist"] objectAtIndex:j] objectForKey:@"file"] == nil)
            {
                for(int g=0; g<[[[[dictionary objectForKey:@"playlist"] objectAtIndex:j] objectForKey:@"playlist"] count]; g++)
                {

                    NSString *serialName = [[[[[dictionary objectForKey:@"playlist"] objectAtIndex:j] objectForKey:@"playlist"] objectAtIndex:g] objectForKey:@"comment"];
                    NSString * newserialName = [serialName stringByReplacingOccurrencesOfString:@"<br>" withString:@""];
                    NSMutableDictionary *serialItemDic = [NSMutableDictionary
                                                         dictionaryWithObjects:@[newserialName, [[[[[dictionary objectForKey:@"playlist"] objectAtIndex:j] objectForKey:@"playlist"] objectAtIndex:g] objectForKey:@"file"]]
                                                         forKeys:@[@"Name",@"Path"]];
                    [playListArray addObject:serialItemDic];
                }
            }
            else
            {
                NSString *serialName = [[[dictionary objectForKey:@"playlist"] objectAtIndex:j] objectForKey:@"comment"];
                NSString * newserialName = [serialName stringByReplacingOccurrencesOfString:@"<br>" withString:@" "];
                NSMutableDictionary *serialItemDic = [NSMutableDictionary
                                                     dictionaryWithObjects:@[newserialName,[[[dictionary objectForKey:@"playlist"] objectAtIndex:j] objectForKey:@"file"]]
                                                     forKeys:@[@"Name",@"Path"]];
                [playListArray addObject:serialItemDic];
            }
            
        }
    }
    return playListArray;
}
- (void) addSerialsToDB:(NSMutableArray*)serialsArray{
    [self.dbManager writeArraySerials:serialsArray];
}

- (NSString*) getLastModifiedDate{
    return [self.dbManager getLastModifiedDate];
}

- (void) updateLastModifiedDate:(NSString*) date{
    [self updateLastModifiedDate:date];
}



#pragma mark - private methods
- (NSMutableArray*) getAllSerials{
    NSMutableArray *json= [self.dbManager getArraySerials];
    
    NSMutableArray *array=[NSMutableArray new];
    
    for (id serial in json) {
        SerialModel* model = [[SerialModel alloc] init];
        
        id idSerial = [serial objectForKey:@"Id"];
        id name = [serial objectForKey:@"Name"];
        id url = [serial objectForKey:@"Url"];
        
        model.Id = idSerial;
        model.Name = name;
        model.Url = url;
        model.ImageURL = [self getImageLinkWithSerailId: idSerial];
        
        [array addObject:model];
    }
    return array;
}
- (NSMutableArray*) getFavoriteSerials{
    NSMutableArray *json= [self.dbManager getArrayFavoriteSerials];
    
    NSMutableArray *array=[NSMutableArray new];
    
    for (id serial in json) {
        SerialModel* model = [[SerialModel alloc] init];
        
        id idSerial = [serial objectForKey:@"Id"];
        id name = [serial objectForKey:@"Name"];
        id url = [serial objectForKey:@"Url"];
        
        model.Id = idSerial;
        model.Name = name;
        model.Url = url;
        model.ImageURL = [self getImageLinkWithSerailId: idSerial];
        
        [array addObject:model];
    }
    return array;
}

- (NSMutableArray*) getNewSerials{
    NSURL *URL = [[NSURL alloc] initWithString:@"http://seasonvar.ru/rss.php"];
    NSString *xmlString = [[NSString alloc] initWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:NULL];
    //NSLog(@"string: %@", xmlString);
    NSDictionary *xmlDoc = [NSDictionary dictionaryWithXMLString:xmlString];
    //NSLog(@"dictionary: %@", xmlDoc);
    
    NSMutableArray *array=[NSMutableArray new];
    
    for (id serial in [[xmlDoc objectForKey:@"channel"] objectForKey:@"item"]) {
        SerialModel* model = [[SerialModel alloc] init];
        
        id title = [serial objectForKey:@"title"];
        id link = [serial objectForKey:@"link"];
        NSString *serialID = [[link componentsSeparatedByString:@"-"] objectAtIndex:1];
        
        
        model.Id = serialID;
        model.Name = title;
        model.Url = link;
        model.ImageURL = [self getImageLinkWithSerailId: serialID];
        
        [array addObject:model];
    }
    
    return array;
}

- (NSURL*)getImageLinkWithSerailId:(NSString*) serialID{
    if(serialID == nil){
        NSURL *imgUrlLink = [[NSURL alloc] initWithString:@""];
        return imgUrlLink;
    }
    
    NSMutableString *imageFromCDN = [[NSMutableString alloc] initWithString:@"http://cdn.seasonvar.ru/oblojka/"];
    [imageFromCDN appendString:serialID];
    [imageFromCDN appendString:@".jpg"];
    NSURL *imgUrlLink = [[NSURL alloc] initWithString:imageFromCDN];
    return imgUrlLink;
}
- (NSURL*)getLargeImageLinkWithSerailId:(NSString*) serialID{
    if(serialID == nil){
        NSURL *imgUrlLink = [[NSURL alloc] initWithString:@""];
        return imgUrlLink;
    }
    
    NSMutableString *imageFromCDN = [[NSMutableString alloc] initWithString:@"http://cdn.seasonvar.ru/oblojka/large/"];
    [imageFromCDN appendString:serialID];
    [imageFromCDN appendString:@".jpg"];
    NSURL *imgUrlLink = [[NSURL alloc] initWithString:imageFromCDN];
    return imgUrlLink;
}

@end
