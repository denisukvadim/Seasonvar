//
//  ConnectionChecker.m
//  SerialPLayer
//
//  Created by Developer Eventsoft on 11.12.16.
//  Copyright © 2016 Vadim Denisuk. All rights reserved.
//

#import "ConnectionChecker.h"
#import <Reachability/Reachability.h>

@implementation ConnectionChecker


//+ (id)sharedInstance
//{
//    static ConnectionChecker *sharedInstance = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        sharedInstance = [[ConnectionChecker alloc] init];
//        
//    });
//    return sharedInstance;
//}

- (BOOL)checkInternetConnection
{
    NSString *urlString = @"http://www.google.com/";
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"HEAD"];
    NSHTTPURLResponse *response;
    
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error: NULL];
    
    return ([response statusCode] == 200) ? YES : NO;

}
@end
