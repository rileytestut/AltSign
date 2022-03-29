//
//  ALTSigner.m
//  AltSign
//
//  Created by Riley Testut on 5/22/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "ALTSigner.h"
#import "ALTAppID.h"
#import "ALTTeam.h"
#import "ALTCertificate.h"
#import "ALTProvisioningProfile.h"
#import "ALTApplication.h"

#import "NSFileManager+Zip.h"
#import "NSError+ALTErrors.h"

#import "alt_ldid.hpp"

#include <string>

#include <openssl/pkcs12.h>
#include <openssl/pem.h>

const char *AppleRootCertificateData = ""
"-----BEGIN CERTIFICATE-----\n"
"MIIEuzCCA6OgAwIBAgIBAjANBgkqhkiG9w0BAQUFADBiMQswCQYDVQQGEwJVUzET\n"
"MBEGA1UEChMKQXBwbGUgSW5jLjEmMCQGA1UECxMdQXBwbGUgQ2VydGlmaWNhdGlv\n"
"biBBdXRob3JpdHkxFjAUBgNVBAMTDUFwcGxlIFJvb3QgQ0EwHhcNMDYwNDI1MjE0\n"
"MDM2WhcNMzUwMjA5MjE0MDM2WjBiMQswCQYDVQQGEwJVUzETMBEGA1UEChMKQXBw\n"
"bGUgSW5jLjEmMCQGA1UECxMdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkx\n"
"FjAUBgNVBAMTDUFwcGxlIFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw\n"
"ggEKAoIBAQDkkakJH5HbHkdQ6wXtXnmELes2oldMVeyLGYne+Uts9QerIjAC6Bg+\n"
"+FAJ039BqJj50cpmnCRrEdCju+QbKsMflZ56DKRHi1vUFjczy8QPTc4UadHJGXL1\n"
"XQ7Vf1+b8iUDulWPTV0N8WQ1IxVLFVkds5T39pyez1C6wVhQZ48ItCD3y6wsIG9w\n"
"tj8BMIy3Q88PnT3zK0koGsj+zrW5DtleHNbLPbU6rfQPDgCSC7EhFi501TwN22IW\n"
"q6NxkkdTVcGvL0Gz+PvjcM3mo0xFfh9Ma1CWQYnEdGILEINBhzOKgbEwWOxaBDKM\n"
"aLOPHd5lc/9nXmW8Sdh2nzMUZaF3lMktAgMBAAGjggF6MIIBdjAOBgNVHQ8BAf8E\n"
"BAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUK9BpR5R2Cf70a40uQKb3\n"
"R01/CF4wHwYDVR0jBBgwFoAUK9BpR5R2Cf70a40uQKb3R01/CF4wggERBgNVHSAE\n"
"ggEIMIIBBDCCAQAGCSqGSIb3Y2QFATCB8jAqBggrBgEFBQcCARYeaHR0cHM6Ly93\n"
"d3cuYXBwbGUuY29tL2FwcGxlY2EvMIHDBggrBgEFBQcCAjCBthqBs1JlbGlhbmNl\n"
"IG9uIHRoaXMgY2VydGlmaWNhdGUgYnkgYW55IHBhcnR5IGFzc3VtZXMgYWNjZXB0\n"
"YW5jZSBvZiB0aGUgdGhlbiBhcHBsaWNhYmxlIHN0YW5kYXJkIHRlcm1zIGFuZCBj\n"
"b25kaXRpb25zIG9mIHVzZSwgY2VydGlmaWNhdGUgcG9saWN5IGFuZCBjZXJ0aWZp\n"
"Y2F0aW9uIHByYWN0aWNlIHN0YXRlbWVudHMuMA0GCSqGSIb3DQEBBQUAA4IBAQBc\n"
"NplMLXi37Yyb3PN3m/J20ncwT8EfhYOFG5k9RzfyqZtAjizUsZAS2L70c5vu0mQP\n"
"y3lPNNiiPvl4/2vIB+x9OYOLUyDTOMSxv5pPCmv/K/xZpwUJfBdAVhEedNO3iyM7\n"
"R6PVbyTi69G3cN8PReEnyvFteO3ntRcXqNx+IjXKJdXZD9Zr1KIkIxH3oayPc4Fg\n"
"xhtbCS+SsvhESPBgOJ4V9T0mZyCKM2r3DYLP3uujL/lTaltkwGMzd/c6ByxW69oP\n"
"IQ7aunMZT7XZNn/Bh1XZp5m5MkL72NVxnn6hUrcbvZNCJBIqxw8dtk2cXmPIS4AX\n"
"UKqK1drk/NAJBzewdXUh\n"
"-----END CERTIFICATE-----\n";

const char *AppleWWDRCertificateData = ""
"-----BEGIN CERTIFICATE-----\n"
"MIIEUTCCAzmgAwIBAgIQfK9pCiW3Of57m0R6wXjF7jANBgkqhkiG9w0BAQsFADBi\n"
"MQswCQYDVQQGEwJVUzETMBEGA1UEChMKQXBwbGUgSW5jLjEmMCQGA1UECxMdQXBw\n"
"bGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxFjAUBgNVBAMTDUFwcGxlIFJvb3Qg\n"
"Q0EwHhcNMjAwMjE5MTgxMzQ3WhcNMzAwMjIwMDAwMDAwWjB1MUQwQgYDVQQDDDtB\n"
"cHBsZSBXb3JsZHdpZGUgRGV2ZWxvcGVyIFJlbGF0aW9ucyBDZXJ0aWZpY2F0aW9u\n"
"IEF1dGhvcml0eTELMAkGA1UECwwCRzMxEzARBgNVBAoMCkFwcGxlIEluYy4xCzAJ\n"
"BgNVBAYTAlVTMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2PWJ/KhZ\n"
"C4fHTJEuLVaQ03gdpDDppUjvC0O/LYT7JF1FG+XrWTYSXFRknmxiLbTGl8rMPPbW\n"
"BpH85QKmHGq0edVny6zpPwcR4YS8Rx1mjjmi6LRJ7TrS4RBgeo6TjMrA2gzAg9Dj\n"
"+ZHWp4zIwXPirkbRYp2SqJBgN31ols2N4Pyb+ni743uvLRfdW/6AWSN1F7gSwe0b\n"
"5TTO/iK1nkmw5VW/j4SiPKi6xYaVFuQAyZ8D0MyzOhZ71gVcnetHrg21LYwOaU1A\n"
"0EtMOwSejSGxrC5DVDDOwYqGlJhL32oNP/77HK6XF8J4CjDgXx9UO0m3JQAaN4LS\n"
"VpelUkl8YDib7wIDAQABo4HvMIHsMBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYDVR0j\n"
"BBgwFoAUK9BpR5R2Cf70a40uQKb3R01/CF4wRAYIKwYBBQUHAQEEODA2MDQGCCsG\n"
"AQUFBzABhihodHRwOi8vb2NzcC5hcHBsZS5jb20vb2NzcDAzLWFwcGxlcm9vdGNh\n"
"MC4GA1UdHwQnMCUwI6AhoB+GHWh0dHA6Ly9jcmwuYXBwbGUuY29tL3Jvb3QuY3Js\n"
"MB0GA1UdDgQWBBQJ/sAVkPmvZAqSErkmKGMMl+ynsjAOBgNVHQ8BAf8EBAMCAQYw\n"
"EAYKKoZIhvdjZAYCAQQCBQAwDQYJKoZIhvcNAQELBQADggEBAK1lE+j24IF3RAJH\n"
"Qr5fpTkg6mKp/cWQyXMT1Z6b0KoPjY3L7QHPbChAW8dVJEH4/M/BtSPp3Ozxb8qA\n"
"HXfCxGFJJWevD8o5Ja3T43rMMygNDi6hV0Bz+uZcrgZRKe3jhQxPYdwyFot30ETK\n"
"XXIDMUacrptAGvr04NM++i+MZp+XxFRZ79JI9AeZSWBZGcfdlNHAwWx/eCHvDOs7\n"
"bJmCS1JgOLU5gm3sUjFTvg+RTElJdI+mUcuER04ddSduvfnSXPN/wmwLCTbiZOTC\n"
"NwMUGdXqapSqqdv+9poIZ4vvK7iqF0mDr8/LvOnP6pVxsLRFoszlh6oKw0E6eVza\n"
"UDSdlTs=\n"
"-----END CERTIFICATE-----\n";

const char *LegacyAppleWWDRCertificateData = ""
"-----BEGIN CERTIFICATE-----\n"
"MIIEIjCCAwqgAwIBAgIIAd68xDltoBAwDQYJKoZIhvcNAQEFBQAwYjELMAkGA1UE\n"
"BhMCVVMxEzARBgNVBAoTCkFwcGxlIEluYy4xJjAkBgNVBAsTHUFwcGxlIENlcnRp\n"
"ZmljYXRpb24gQXV0aG9yaXR5MRYwFAYDVQQDEw1BcHBsZSBSb290IENBMB4XDTEz\n"
"MDIwNzIxNDg0N1oXDTIzMDIwNzIxNDg0N1owgZYxCzAJBgNVBAYTAlVTMRMwEQYD\n"
"VQQKDApBcHBsZSBJbmMuMSwwKgYDVQQLDCNBcHBsZSBXb3JsZHdpZGUgRGV2ZWxv\n"
"cGVyIFJlbGF0aW9uczFEMEIGA1UEAww7QXBwbGUgV29ybGR3aWRlIERldmVsb3Bl\n"
"ciBSZWxhdGlvbnMgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwggEiMA0GCSqGSIb3\n"
"DQEBAQUAA4IBDwAwggEKAoIBAQDKOFSmy1aqyCQ5SOmM7uxfuH8mkbw0U3rOfGOA\n"
"YXdkXqUHI7Y5/lAtFVZYcC1+xG7BSoU+L/DehBqhV8mvexj/avoVEkkVCBmsqtsq\n"
"Mu2WY2hSFT2Miuy/axiV4AOsAX2XBWfODoWVN2rtCbauZ81RZJ/GXNG8V25nNYB2\n"
"NqSHgW44j9grFU57Jdhav06DwY3Sk9UacbVgnJ0zTlX5ElgMhrgWDcHld0WNUEi6\n"
"Ky3klIXh6MSdxmilsKP8Z35wugJZS3dCkTm59c3hTO/AO0iMpuUhXf1qarunFjVg\n"
"0uat80YpyejDi+l5wGphZxWy8P3laLxiX27Pmd3vG2P+kmWrAgMBAAGjgaYwgaMw\n"
"HQYDVR0OBBYEFIgnFwmpthhgi+zruvZHWcVSVKO3MA8GA1UdEwEB/wQFMAMBAf8w\n"
"HwYDVR0jBBgwFoAUK9BpR5R2Cf70a40uQKb3R01/CF4wLgYDVR0fBCcwJTAjoCGg\n"
"H4YdaHR0cDovL2NybC5hcHBsZS5jb20vcm9vdC5jcmwwDgYDVR0PAQH/BAQDAgGG\n"
"MBAGCiqGSIb3Y2QGAgEEAgUAMA0GCSqGSIb3DQEBBQUAA4IBAQBPz+9Zviz1smwv\n"
"j+4ThzLoBTWobot9yWkMudkXvHcs1Gfi/ZptOllc34MBvbKuKmFysa/Nw0Uwj6OD\n"
"Dc4dR7Txk4qjdJukw5hyhzs+r0ULklS5MruQGFNrCk4QttkdUGwhgAqJTleMa1s8\n"
"Pab93vcNIx0LSiaHP7qRkkykGRIZbVf1eliHe2iK5IaMSuviSRSqpd1VAKmuu0sw\n"
"ruGgsbwpgOYJd+W+NKIByn/c4grmO7i77LpilfMFY0GCzQ87HUyVpNur+cmV6U/k\n"
"TecmmYHpvPm0KdIBembhLoz2IYrF+Hjhga6/05Cdqa3zr/04GpZnMBxRpVzscYqC\n"
"tGwPDBUf\n"
"-----END CERTIFICATE-----\n";

std::string CertificatesContent(ALTCertificate *altCertificate)
{
    NSData *altCertificateP12Data = [altCertificate p12Data];
    
    BIO *inputP12Buffer = BIO_new(BIO_s_mem());
    BIO_write(inputP12Buffer, altCertificateP12Data.bytes, (int)altCertificateP12Data.length);
    
    auto inputP12 = d2i_PKCS12_bio(inputP12Buffer, NULL);
    
    // Extract key + certificate from .p12.
    EVP_PKEY *key;
    X509 *certificate;
    PKCS12_parse(inputP12, "", &key, &certificate, NULL);
    
    // Prepare certificate chain of trust.
    auto *certificates = sk_X509_new(NULL);
    
    BIO *rootCertificateBuffer = BIO_new_mem_buf(AppleRootCertificateData, (int)strlen(AppleRootCertificateData));
    BIO *wwdrCertificateBuffer = nil;
    
    unsigned long issuerHash = X509_issuer_name_hash(certificate);
    if (issuerHash == 0x817d2f7a)
    {
        // Use legacy WWDR certificate.
        wwdrCertificateBuffer = BIO_new_mem_buf(LegacyAppleWWDRCertificateData, (int)strlen(LegacyAppleWWDRCertificateData));
    }
    else
    {
        // Use latest WWDR certificate.
        wwdrCertificateBuffer = BIO_new_mem_buf(AppleWWDRCertificateData, (int)strlen(AppleWWDRCertificateData));
    }
    
    auto rootCertificate = PEM_read_bio_X509(rootCertificateBuffer, NULL, NULL, NULL);
    if (rootCertificate != NULL)
    {
        sk_X509_push(certificates, rootCertificate);
    }
    
    auto wwdrCertificate = PEM_read_bio_X509(wwdrCertificateBuffer, NULL, NULL, NULL);
    if (wwdrCertificate != NULL)
    {
        sk_X509_push(certificates, wwdrCertificate);
    }
    
    // Create new .p12 in memory with private key and certificate chain.
    char emptyString[] = "";
    auto outputP12 = PKCS12_create(emptyString, emptyString, key, certificate, certificates, 0, 0, 0, 0, 0);
    
    BIO *outputP12Buffer = BIO_new(BIO_s_mem());
    i2d_PKCS12_bio(outputP12Buffer, outputP12);
    
    char *buffer = NULL;
    NSUInteger size = BIO_get_mem_data(outputP12Buffer, &buffer);
    
    NSData *p12Data = [NSData dataWithBytes:buffer length:size];
    
    // Free .p12 structures
    PKCS12_free(inputP12);
    PKCS12_free(outputP12);
    
    BIO_free(wwdrCertificateBuffer);
    BIO_free(rootCertificateBuffer);
    
    BIO_free(inputP12Buffer);
    BIO_free(outputP12Buffer);
    
    std::string output((const char *)p12Data.bytes, (size_t)p12Data.length);
    return output;
}

@implementation ALTSigner

+ (void)load
{
    OpenSSL_add_all_algorithms();
}

- (instancetype)initWithTeam:(ALTTeam *)team certificate:(ALTCertificate *)certificate
{
    self = [super init];
    if (self)
    {
        _team = team;
        _certificate = certificate;
    }
    
    return self;
}

- (NSProgress *)signAppAtURL:(NSURL *)appURL provisioningProfiles:(NSArray<ALTProvisioningProfile *> *)profiles completionHandler:(void (^)(BOOL success, NSError *error))completionHandler
{    
    NSProgress *progress = [NSProgress discreteProgressWithTotalUnitCount:1];
    
    NSURL *ipaURL = nil;
    NSURL *appBundleURL = nil;
    
    void (^finish)(BOOL, NSError *) = ^(BOOL success, NSError *error) {
        if (ipaURL != nil)
        {
            NSError *removeError = nil;
            if (![[NSFileManager defaultManager] removeItemAtURL:[ipaURL URLByDeletingLastPathComponent] error:&removeError])
            {
                NSLog(@"Failed to clean up after resigning. %@", removeError);
            }
        }
        
        completionHandler(success, error);
    };
    
    __block NSError *error = nil;
    
    if ([appURL.pathExtension.lowercaseString isEqualToString:@"ipa"])
    {
        ipaURL = appURL;
        
        NSURL *outputDirectoryURL = [[appURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:[[NSUUID UUID] UUIDString] isDirectory:YES];
        if (![[NSFileManager defaultManager] createDirectoryAtURL:outputDirectoryURL withIntermediateDirectories:YES attributes:nil error:&error])
        {
            finish(NO, error);
            return progress;
        }
        
        appBundleURL = [[NSFileManager defaultManager] unzipAppBundleAtURL:appURL toDirectory:outputDirectoryURL error:&error];
        if (appBundleURL == nil)
        {
            finish(NO, [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorMissingAppBundle userInfo:@{NSUnderlyingErrorKey: error}]);
            return progress;
        }
    }
    else
    {
        appBundleURL = appURL;
    }
    
    NSBundle *appBundle = [NSBundle bundleWithURL:appBundleURL];
    if (appBundle == nil)
    {
        finish(NO, [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorInvalidApp userInfo:nil]);
        return progress;
    }
    
    ALTApplication *application = [[ALTApplication alloc] initWithFileURL:appBundleURL];
    if (application == nil)
    {
        finish(NO, [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorInvalidApp userInfo:nil]);
        return progress;
    }
    
    NSDirectoryEnumerator *countEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:appURL
                                                                  includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                                                     options:0
                                                                                errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
                                                                                    if (error) {
                                                                                        NSLog(@"[Error] %@ (%@)", error, url);
                                                                                        return NO;
                                                                                    }
                                                                                    
                                                                                    return YES;
                                                                                }];
        
    NSInteger totalCount = 0;
    for (NSURL *__unused fileURL in countEnumerator)
    {
        NSNumber *isDirectory = nil;
        if (![fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil] || [isDirectory boolValue])
        {
            continue;
        }
        
        // Ignore CodeResources files.
        if ([[fileURL lastPathComponent] isEqualToString:@"CodeResources"])
        {
            continue;
        }
        
        totalCount++;
    }
    
    progress.totalUnitCount = totalCount;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSMutableDictionary<NSURL *, NSString *> *entitlementsByFileURL = [NSMutableDictionary dictionary];
        
        ALTProvisioningProfile *(^profileForApp)(ALTApplication *) = ^ALTProvisioningProfile *(ALTApplication *app) {
            // Assume for now that apps don't have 100s of app extensions 🤷‍♂️
            for (ALTProvisioningProfile *profile in profiles)
            {
                if ([profile.bundleIdentifier isEqualToString:app.bundleIdentifier])
                {
                    return profile;
                }
            }
            
            return nil;
        };
        
        NSError * (^prepareApp)(ALTApplication *) = ^NSError *(ALTApplication *app) {
            ALTProvisioningProfile *profile = profileForApp(app);
            if (profile == nil)
            {
                return [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorMissingProvisioningProfile userInfo:nil];
            }
            
            NSURL *profileURL = [app.fileURL URLByAppendingPathComponent:@"embedded.mobileprovision"];
            [profile.data writeToURL:profileURL atomically:YES];
            
            NSString *additionalEntitlements = nil;
            if (app.hasPrivateEntitlements)
            {
                NSRange commentStartRange = [app.entitlementsString rangeOfString:@"<!---><!-->"];
                NSRange commentEndRange = [app.entitlementsString rangeOfString:@"<!-- -->"];
                if (commentStartRange.location != NSNotFound && commentEndRange.location != NSNotFound && commentEndRange.location > commentStartRange.location)
                {
                    // Most likely using private (commented out) entitlements to exploit Psychic Paper https://github.com/Siguza/psychicpaper
                    // Assume they know what they are doing and extract private entitlements to merge with profile's.
                    
                    NSRange commentRange = NSMakeRange(commentStartRange.location, (commentEndRange.location + commentEndRange.length) - commentStartRange.location);
                    NSString *commentedEntitlements = [app.entitlementsString substringWithRange:commentRange];
                    
                    additionalEntitlements = commentedEntitlements;
                }
            }
            
            NSData *entitlementsData = [NSPropertyListSerialization dataWithPropertyList:profile.entitlements format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
            if (entitlementsData == nil)
            {
                return error;
            }
            
            NSMutableString *entitlements = [[NSMutableString alloc] initWithData:entitlementsData encoding:NSUTF8StringEncoding];
            if (additionalEntitlements != nil)
            {
                // Insert additional entitlements after first occurence of <dict>.
                NSRange entitlementsStartRange = [entitlements rangeOfString:@"<dict>"];
                [entitlements insertString:additionalEntitlements atIndex:entitlementsStartRange.location + entitlementsStartRange.length];
            }
            
            NSURL *resolvedURL = [app.fileURL URLByResolvingSymlinksInPath];
            entitlementsByFileURL[resolvedURL] = entitlements;
            
            return nil;
        };
        
        NSError *prepareError = prepareApp(application);
        if (prepareError != nil)
        {
            finish(NO, prepareError);
            return;
        }
        
        NSURL *pluginsURL = [appBundle builtInPlugInsURL];
        
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:pluginsURL
                                                                 includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil];
        
        for (NSURL *extensionURL in enumerator)
        {
            ALTApplication *appExtension = [[ALTApplication alloc] initWithFileURL:extensionURL];
            if (appExtension == nil)
            {
                prepareError = [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorInvalidApp userInfo:nil];
                break;
            }
            
            NSError *error = prepareApp(appExtension);
            if (error != nil)
            {
                prepareError = error;
                break;
            }
        }
        
        if (prepareError != nil)
        {
            finish(NO, prepareError);
            return;
        }
        
        try
        {
            // Sign application
            ldid::DiskFolder appBundle(application.fileURL.fileSystemRepresentation);
            std::string key = CertificatesContent(self.certificate);
            
            ldid::Sign("", appBundle, key, "",
                       ldid::fun([&](const std::string &path, const std::string &binaryEntitlements) -> std::string {
                NSString *filename = [NSString stringWithCString:path.c_str() encoding:NSUTF8StringEncoding];
                
                NSURL *fileURL = nil;
                
                if (filename.length == 0)
                {
                    fileURL = application.fileURL;
                }
                else
                {
                    fileURL = [application.fileURL URLByAppendingPathComponent:filename isDirectory:YES];
                }
                
                NSURL *resolvedURL = [fileURL URLByResolvingSymlinksInPath];
                
                NSString *entitlements = entitlementsByFileURL[resolvedURL];
                return entitlements.UTF8String;
            }),
                       ldid::fun([&](const std::string &string) {
                progress.completedUnitCount += 1;
            }),
                       ldid::fun([&](const double signingProgress) {
            }));
            
            
            // Dispatch after to allow time to finish signing binary.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if (ipaURL != nil)
                {
                    NSURL *resignedIPAURL = [[NSFileManager defaultManager] zipAppBundleAtURL:appBundleURL error:&error];
                    
                    if (![[NSFileManager defaultManager] replaceItemAtURL:ipaURL withItemAtURL:resignedIPAURL backupItemName:nil options:0 resultingItemURL:nil error:&error])
                    {
                        finish(NO, error);
                        return;
                    }
                }
                
                finish(YES, nil);
            });
        }
        catch (std::exception& exception)
        {
            NSError *error = [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorUnknown userInfo:@{NSLocalizedDescriptionKey: @(exception.what())}];
            finish(NO, error);
        }
    });

    return progress;
}

@end
