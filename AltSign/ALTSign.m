//
//  ALTSign.m
//  AltSign
//
//  Created by Riley Testut on 5/10/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "ALTSign.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALTSign ()

@property (nonatomic, readonly) NSURLSession *session;

@property (nonatomic, readonly) NSString *protocolVersion;
@property (nonatomic, readonly) NSString *appIDKey;

@end

NS_ASSUME_NONNULL_END

@implementation ALTSign

+ (instancetype)shared
{
    static ALTSign *_sign = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sign = [[self alloc] init];
    });
    
    return _sign;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
        
        _protocolVersion = @"A1234";
        _appIDKey = @"ba2ec180e6ca6e6c6a542255453b24d6e6e5b2be0cc48bc1b0d8ad64cfe0228f";
    }
    
    return self;
}

#pragma mark - Authentication -

- (void)authenticateWithAppleID:(NSString *)appleID password:(NSString *)password completionHandler:(void (^)(ALTAccount *account, NSError *error))completionHandler
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://idmsa.apple.com/IDMSWebAuth/clientDAW.cgi"]];
    request.HTTPMethod = @"POST";
    
    NSString *encodedAppleID = [appleID stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    NSString *encodedPassword = [password stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    
    NSString *body = [NSString stringWithFormat:@"format=plist&appIdKey=%@&appleId=%@&password=%@&userLocale=en_US&protocolVersion=%@",
                      self.appIDKey, encodedAppleID, encodedPassword, self.protocolVersion];
    
    NSDictionary<NSString *, NSString *> *headers = @{
                                                      @"Content-Type": @"application/x-www-form-urlencoded",
                                                      @"User-Agent": @"Xcode",
                                                      @"Accept": @"text/x-xml-plist",
                                                      @"Accept-Language": @"en-us",
                                                      @"Connection": @"keep-alive",
                                                      };
    
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [request setValue:value forHTTPHeaderField:key];
    }];
    
    NSData *encodedBody = [body dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = encodedBody;
    
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil)
        {
            completionHandler(nil, error);
            return;
        }
        
        NSError *parseError = nil;
        NSDictionary *responseDictionary = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:&parseError];
        
        if (responseDictionary == nil)
        {
            NSError *error = [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorInvalidResponse userInfo:@{NSUnderlyingErrorKey: parseError}];
            completionHandler(nil, error);
            return;
        }
        
        ALTAccount *account = [[ALTAccount alloc] initWithAppleID:appleID responseDictionary:responseDictionary];
        completionHandler(account, nil);
    }];
    
    [dataTask resume];
}

@end
