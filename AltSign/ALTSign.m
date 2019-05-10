//
//  ALTSign.m
//  AltSign
//
//  Created by Riley Testut on 5/10/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "ALTSign.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const ALTAuthenticationProtocolVersion = @"A1234";
NSString *const ALTProtocolVersion = @"QH65B2";
NSString *const ALTAppIDKey = @"ba2ec180e6ca6e6c6a542255453b24d6e6e5b2be0cc48bc1b0d8ad64cfe0228f";
NSString *const ALTClientID = @"XABBG36SBA";

@interface ALTSign ()

@property (nonatomic, readonly) NSURLSession *session;

@property (nonatomic, copy, readonly) NSURL *baseURL;

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
        
        _baseURL = [[NSURL URLWithString:[NSString stringWithFormat:@"https://developerservices2.apple.com/services/%@/", ALTProtocolVersion]] copy];
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
                      ALTAppIDKey, encodedAppleID, encodedPassword, ALTAuthenticationProtocolVersion];
    
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
        if (data == nil)
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
        if (account != nil)
        {
            completionHandler(account, nil);
        }
        else
        {
            NSError *error = [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorInvalidResponse userInfo:nil];
            completionHandler(nil, error);
        }
    }];
    
    [dataTask resume];
}

#pragma mark - Teams -

- (void)fetchTeamsForAccount:(ALTAccount *)account completionHandler:(void (^)(NSArray<ALTTeam *> *teams, NSError *error))completionHandler
{
    NSURL *URL = [NSURL URLWithString:@"listTeams.action" relativeToURL:self.baseURL];
    
    [self sendRequestWithURL:URL additionalParameters:nil account:account team:nil completionHandler:^(NSDictionary *responseDictionary, NSError *error) {
        if (responseDictionary == nil)
        {
            completionHandler(nil, error);
            return;
        }
        
        NSArray *array = responseDictionary[@"teams"];
        if (array == nil)
        {
            NSError *error = [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorInvalidResponse userInfo:nil];
            completionHandler(nil, error);
            return;
        }
        
        NSMutableArray *teams = [NSMutableArray array];
        for (NSDictionary *dictionary in array)
        {
            ALTTeam *team = [[ALTTeam alloc] initWithAccount:account responseDictionary:dictionary];
            if (team == nil)
            {
                NSError *error = [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorInvalidResponse userInfo:nil];
                completionHandler(nil, error);
                return;
            }
            
            [teams addObject:team];
        }
        
        completionHandler(teams, nil);
    }];
}

#pragma mark - Devices -

- (void)fetchDevicesForTeam:(ALTTeam *)team completionHandler:(void (^)(NSArray<ALTDevice *> * _Nullable, NSError * _Nullable))completionHandler
{
    NSURL *URL = [NSURL URLWithString:@"ios/listDevices.action" relativeToURL:self.baseURL];
    
    [self sendRequestWithURL:URL additionalParameters:nil account:team.account team:team completionHandler:^(NSDictionary *responseDictionary, NSError *error) {
        if (responseDictionary == nil)
        {
            completionHandler(nil, error);
            return;
        }
        
        NSArray *array = responseDictionary[@"devices"];
        if (array == nil)
        {
            NSError *error = [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorInvalidResponse userInfo:nil];
            completionHandler(nil, error);
            return;
        }
        
        NSMutableArray *devices = [NSMutableArray array];
        for (NSDictionary *dictionary in array)
        {
            ALTDevice *device = [[ALTDevice alloc] initWithResponseDictionary:dictionary];
            if (device == nil)
            {
                NSError *error = [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorInvalidResponse userInfo:nil];
                completionHandler(nil, error);
                return;
            }
            
            [devices addObject:device];
        }
        
        completionHandler(devices, nil);
    }];
}

- (void)registerDeviceWithName:(NSString *)name identifier:(NSString *)identifier team:(ALTTeam *)team completionHandler:(void (^)(ALTDevice * _Nullable, NSError * _Nullable))completionHandler
{
    NSURL *URL = [NSURL URLWithString:@"ios/addDevice.action" relativeToURL:self.baseURL];
    
    [self sendRequestWithURL:URL additionalParameters:@{@"deviceNumber": identifier, @"name": name} account:team.account team:team completionHandler:^(NSDictionary *responseDictionary, NSError *error) {
        if (responseDictionary == nil)
        {
            completionHandler(nil, error);
            return;
        }
        
        NSDictionary *dictionary = responseDictionary[@"device"];
        if (dictionary == nil)
        {
            NSError *error = [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorInvalidResponse userInfo:nil];
            completionHandler(nil, error);
            return;
        }
        
        ALTDevice *device = [[ALTDevice alloc] initWithResponseDictionary:dictionary];
        if (device == nil)
        {
            NSError *error = [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorInvalidResponse userInfo:nil];
            completionHandler(nil, error);
            return;
        }
        
        completionHandler(device, nil);
    }];
}

#pragma mark - Requests -

- (void)sendRequestWithURL:(NSURL *)requestURL additionalParameters:(nullable NSDictionary *)additionalParameters account:(ALTAccount *)account team:(nullable ALTTeam *)team completionHandler:(void (^)(NSDictionary *responseDictionary, NSError *error))completionHandler
{
    NSMutableDictionary<NSString *, NSString *> *parameters = [@{
                                                                 @"DTDK_Platform": @"ios",
                                                                 @"clientId": ALTClientID,
                                                                 @"protocolVersion": ALTProtocolVersion,
                                                                 @"requestId": [[[NSUUID UUID] UUIDString] uppercaseString],
                                                                 @"myacinfo": account.cookie,
                                                                 @"userLocale": @[@"en_US"],
                                                                 } mutableCopy];
    
    if (team != nil)
    {
        parameters[@"teamId"] = team.identifier;
    }
    
    if (account != nil)
    {
        parameters[@"myacinfo"] = account.cookie;
    }
    
    [additionalParameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        parameters[key] = value;
    }];
    
    NSError *serializationError = nil;
    NSData *bodyData = [NSPropertyListSerialization dataWithPropertyList:parameters format:NSPropertyListXMLFormat_v1_0 options:0 error:&serializationError];
    if (bodyData == nil)
    {
        NSError *error = [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorInvalidParameters userInfo:@{NSUnderlyingErrorKey: serializationError}];
        completionHandler(nil, error);
        return;
    }
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?clientId=%@", requestURL.absoluteString, ALTClientID]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    request.HTTPBody = bodyData;
    
    NSDictionary<NSString *, NSString *> *httpHeaders = @{
                                                          @"Content-Type": @"text/x-xml-plist",
                                                          @"User-Agent": @"Xcode",
                                                          @"Accept": @"text/x-xml-plist",
                                                          @"Accept-Language": @"en-us",
                                                          @"Connection": @"keep-alive",
                                                          @"X-Xcode-Version": @"7.0 (7A120f)",
                                                          @"Cookie": [NSString stringWithFormat:@"myacinfo=%@", account.cookie],
                                                          };
    
    [httpHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [request setValue:value forHTTPHeaderField:key];
    }];
    
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data == nil)
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
        
        completionHandler(responseDictionary, nil);
    }];
    
    [dataTask resume];
}

@end
