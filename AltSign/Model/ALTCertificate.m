//
//  ALTCertificate.m
//  AltSign
//
//  Created by Riley Testut on 5/10/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "ALTCertificate.h"

#include <openssl/pem.h>
#include <openssl/pkcs12.h>

@implementation ALTCertificate

- (instancetype)initWithResponseDictionary:(NSDictionary *)responseDictionary
{
    self = [super init];
    if (self)
    {
        NSString *name = responseDictionary[@"name"];
        NSString *identifier = responseDictionary[@"certificateId"];
        NSString *serialNumber = responseDictionary[@"serialNumber"] ?: responseDictionary[@"serialNum"];
        
        if (name == nil || identifier == nil || serialNumber == nil)
        {
            return nil;
        }
        
        _name = [name copy];
        _identifier = [identifier copy];
        _serialNumber = [serialNumber copy];
        
        NSData *data = responseDictionary[@"certContent"];
        if (data != nil)
        {
            NSString *base64Data = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            
            NSString *content = [NSString stringWithFormat:@"-----BEGIN CERTIFICATE-----\n%@\n-----END CERTIFICATE-----", base64Data];
            NSData *pemData = [content dataUsingEncoding:NSUTF8StringEncoding];
            
            _data = [pemData copy];
        }
    }
    
    return self;
}

#pragma mark - NSObject -

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, Name: %@, ID: %@, SN: %@>", NSStringFromClass([self class]), self, self.name, self.identifier, self.serialNumber];
}

- (BOOL)isEqual:(id)object
{
    ALTCertificate *certificate = (ALTCertificate *)object;
    if (![certificate isKindOfClass:[ALTCertificate class]])
    {
        return NO;
    }
    
    BOOL isEqual = (self.identifier == certificate.identifier);
    return isEqual;
}

- (NSUInteger)hash
{
    return self.identifier.hash;
}

#pragma mark - ALTCertificate -

- (nullable NSData *)p12Data
{
    BIO *certificateBuffer = BIO_new(BIO_s_mem());
    BIO *privateKeyBuffer = BIO_new(BIO_s_mem());
    
    BIO_write(certificateBuffer, self.data.bytes, (int)self.data.length);
    BIO_write(privateKeyBuffer, self.privateKey.bytes, (int)self.privateKey.length);
    
    X509 *certificate = nil;
    PEM_read_bio_X509(certificateBuffer, &certificate, 0, 0);
    
    EVP_PKEY *privateKey = nil;
    PEM_read_bio_PrivateKey(privateKeyBuffer, &privateKey, 0, 0);
    
    char emptyString[] = "";
    char password[] = "";
    PKCS12 *outputP12 = PKCS12_create(password, emptyString, privateKey, certificate, NULL, 0, 0, 0, 0, 0);
    
    BIO *p12Buffer = BIO_new(BIO_s_mem());
    i2d_PKCS12_bio(p12Buffer, outputP12);
    
    char *buffer = NULL;
    NSUInteger size = BIO_get_mem_data(p12Buffer, &buffer);
    
    NSData *p12Data = [NSData dataWithBytes:buffer length:size];
    
    BIO_free(p12Buffer);
    PKCS12_free(outputP12);
    
    EVP_PKEY_free(privateKey);
    X509_free(certificate);
    
    BIO_free(privateKeyBuffer);
    BIO_free(certificateBuffer);
    
    return p12Data;
}

@end
