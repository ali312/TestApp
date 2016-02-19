//
//  SocketClient.m
//  TestApp
//
//  Created by Антон Кузнецов on 19/02/16.
//  Copyright © 2016 thelightprj. All rights reserved.
//

#import "SocketClient.h"
#import <SocketRocket/SRWebSocket.h>

static NSString *const SocketURLString = @"ws://52.29.182.220:8080/customer-gateway/customer";

NSString *const kUserLoggedIn = @"UserLoggedIn";
NSString *const kUserLoggedOut = @"UserLoggedOut";

@interface SocketClient () <SRWebSocketDelegate>

@property (nonatomic, copy) void (^loginCompletionBlick)(BOOL success, NSDictionary *response);

@end

@implementation SocketClient {
    SRWebSocket *currentSocket_;
    NSTimer *currentLoginTimer_;
    NSInteger currentMessageID_;
}

+ (instancetype)shared {
    static SocketClient *sharedInstance_;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance_ = [[SocketClient alloc] init];
    });
    
    return sharedInstance_;
}

- (instancetype)init {
    self = [super init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    _currentToken  = [defaults stringForKey:@"api_token"];
    _expirationDate = [defaults objectForKey:@"api_token_expiration_date"];
    
    return self;
}

#pragma mark - Connection Handling

- (void)open {
    NSURL *url = [NSURL URLWithString:SocketURLString];
    currentSocket_ = [[SRWebSocket alloc] initWithURL:url];
    currentSocket_.delegate = self;
    [currentSocket_ open];
    currentMessageID_ = 0;
}

- (void)close {
    [currentSocket_ close];
    currentSocket_.delegate = nil;
    currentSocket_ = nil;
}

- (BOOL)isOpen {
    return (currentSocket_ != nil && !(currentSocket_.readyState == SR_CLOSING ||
                                       currentSocket_.readyState == SR_CLOSED));
}

#pragma mark - Login Handling

- (void)loginWithEmail:(NSString *)email
              password:(NSString *)password
       completionBlock:(void (^)(BOOL success, NSDictionary *response))completionBlock {
    _loginCompletionBlick = completionBlock;
    currentMessageID_++;
    [self sendMessageWithDictionary:@{
                                      @"type" : @"LOGIN_CUSTOMER",
                                      @"sequence_id":@(currentMessageID_).stringValue,
                                      @"data": @{
                                              @"email":email,
                                              @"password":password
                                              }
                                      }];
    
    currentLoginTimer_ = [NSTimer scheduledTimerWithTimeInterval:30
                                                          target:self
                                                        selector:@selector(timeOutLogin)
                                                        userInfo:nil
                                                         repeats:NO];
}

- (void)logout {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"api_token_expiration_date"];
    [defaults removeObjectForKey:@"api_token"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedOut
                                                        object:nil];
}

- (BOOL)isLoggedIn {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *apiToken = [defaults stringForKey:@"api_token"];
    
    if (apiToken.length > 0) {
        NSDate *expirationDate = [defaults objectForKey:@"api_token_expiration_date"];
        NSDate *now = [NSDate date];
        
        NSComparisonResult result = [now compare:expirationDate];
        
        switch (result) {
            case NSOrderedAscending:
                return YES;
                break;
            default:
                return NO;
                break;
        }
    }
    
    return NO;
}

- (void)timeOutLogin {
    currentLoginTimer_ = nil;
    if (_loginCompletionBlick != nil) {
        _loginCompletionBlick(NO, nil);
        _loginCompletionBlick = nil;
    }
}

#pragma mark - SRWebSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSError *e;
    NSObject *obj = [NSJSONSerialization JSONObjectWithData:jsonData
                                                    options:0
                                                      error:&e];
    NSDictionary *dict;
    if ([obj isKindOfClass:[NSArray class]]) {
        dict = ((NSArray *)obj).firstObject;
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        dict = (NSDictionary *)obj;
    }
    
    NSLog(@"Socket Message: %@", dict);
    
    NSString *type = dict[@"type"];
    NSString *sequenceId = dict[@"sequence_id"];
    NSDictionary *data = dict[@"data"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (sequenceId.integerValue == currentMessageID_) {
        if ([type isEqualToString:@"CUSTOMER_API_TOKEN"]) {
            [currentLoginTimer_ invalidate];
            
            NSString *apiToken = data[@"api_token"];
            _currentToken = apiToken;
            
            NSString *expiration_string = data[@"api_token_expiration_date"];
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
            NSDate *dateFromString = [dateFormatter dateFromString:expiration_string];
            _expirationDate = dateFromString;
            
            [defaults setObject:dateFromString
                         forKey:@"api_token_expiration_date"];
            
            [defaults setObject:apiToken
                         forKey:@"api_token"];
            
            [defaults synchronize];
            
            if (_loginCompletionBlick != nil) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedIn
                                                                    object:nil];
                
                _loginCompletionBlick(YES, data);
                _loginCompletionBlick = nil;
            }
        } else {
            [defaults removeObjectForKey:@"api_token_expiration_date"];
            [defaults removeObjectForKey:@"api_token"];
            
            [defaults synchronize];
            
            _currentToken = nil;
            _expirationDate = nil;
            
            [currentLoginTimer_ invalidate];
            if (_loginCompletionBlick != nil) {
                _loginCompletionBlick(NO, data);
                _loginCompletionBlick = nil;
            }
        }
    }
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"Did open socket");
    
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"Socket Error %@", error.description);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"Socket Fail %@", reason);
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    NSLog(@"Socket Message");
}

- (void)sendMessageWithDictionary:(NSDictionary *)dictionary {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                       options:0
                                                         error:nil];
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                 encoding:NSUTF8StringEncoding];
    NSLog(@"Sending message: %@", jsonString);
    [currentSocket_ send:jsonString];
}

@end
