//
//  SocketClient.h
//  TestApp
//
//  Created by Антон Кузнецов on 19/02/16.
//  Copyright © 2016 thelightprj. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kUserLoggedIn;
extern NSString *const kUserLoggedOut;

@interface SocketClient : NSObject

@property (nonatomic, strong, readonly) NSString *currentToken;
@property (nonatomic, strong, readonly) NSDate *expirationDate;

+ (instancetype)shared;

- (void)open;
- (void)close;
- (BOOL)isOpen;
- (BOOL)isLoggedIn;

- (void)loginWithEmail:(NSString *)email
              password:(NSString *)password
       completionBlock:(void (^)(BOOL success, NSDictionary *response))completionBlock;

- (void)logout;

@end
