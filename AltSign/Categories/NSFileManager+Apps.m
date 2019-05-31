//
//  NSFileManager+Apps.m
//  AltSign
//
//  Created by Riley Testut on 5/28/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "NSFileManager+Apps.h"

#import "NSError+ALTErrors.h"

#include "zip.h"
#include "unzip.h"

int ALTReadBufferSize = 8192;
int ALTMaxFilenameLength = 512;
char ALTDirectoryDeliminator = '/';

#define READ_BUFFER_SIZE 8192
#define MAX_FILENAME 512

@implementation NSFileManager (Apps)

- (nullable NSURL *)unzipAppBundleAtURL:(NSURL *)ipaURL toDirectory:(NSURL *)directoryURL error:(NSError **)error
{
    unzFile zipFile = unzOpen(ipaURL.fileSystemRepresentation);
    if (zipFile == NULL)
    {
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:@{NSURLErrorKey: ipaURL}];
        return nil;
    }
    
    FILE *outputFile = nil;
    
    void (^finish)(void) = ^{
        if (outputFile != nil)
        {
            fclose(outputFile);
        }
        
        unzCloseCurrentFile(zipFile);
        unzClose(zipFile);
    };
    
    unz_global_info zipInfo;
    if (unzGetGlobalInfo(zipFile, &zipInfo) != UNZ_OK)
    {
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{NSURLErrorKey: ipaURL}];
        
        finish();
        return nil;
    }
    
    NSString *appBundlePath = nil;
    
    char buffer[ALTReadBufferSize];
    
    for (int i = 0; i < zipInfo.number_entry; i++)
    {
        unz_file_info info;
        char cFilename[ALTMaxFilenameLength];
        
        if (unzGetCurrentFileInfo(zipFile, &info, cFilename, ALTMaxFilenameLength, NULL, 0, NULL, 0) != UNZ_OK)
        {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:@{NSURLErrorKey: ipaURL}];
            
            finish();
            return nil;
        }
        
        NSString *filename = [[NSString alloc] initWithCString:cFilename encoding:NSUTF8StringEncoding];
        if ([filename hasPrefix:@"__MACOSX"])
        {
            if (i + 1 < zipInfo.number_entry)
            {
                if (unzGoToNextFile(zipFile) != UNZ_OK)
                {
                    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:@{NSFilePathErrorKey: filename}];
                    
                    finish();
                    return nil;
                }
            }
            
            continue;
        }
        
        NSURL *fileURL = [directoryURL URLByAppendingPathComponent:filename];
        
        if ([filename characterAtIndex:filename.length - 1] == ALTDirectoryDeliminator)
        {
            // Directory
            
            if ([filename.pathExtension isEqualToString:@"app"])
            {
                appBundlePath = filename;
            }
            
            if (![self createDirectoryAtURL:fileURL withIntermediateDirectories:YES attributes:nil error:error])
            {
                return nil;
            }
        }
        else
        {
            // File
            
            if (unzOpenCurrentFile(zipFile) != UNZ_OK)
            {
                *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:@{NSURLErrorKey: fileURL}];
                
                finish();
                return nil;
            }
            
            outputFile = fopen(fileURL.fileSystemRepresentation, "wb");
            if (outputFile == NULL)
            {
                NSError *underlyingError = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{NSURLErrorKey: fileURL}];
                *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSURLErrorKey: fileURL, NSUnderlyingErrorKey: underlyingError}];
                
                finish();
                return nil;
            }
            
            int result = UNZ_OK;
            
            do
            {
                result = unzReadCurrentFile(zipFile, buffer, ALTReadBufferSize);
                
                if (result < 0)
                {
                    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:@{NSURLErrorKey: fileURL}];
                    
                    finish();
                    return nil;
                }
                
                size_t count = fwrite(buffer, result, 1, outputFile);
                if (result > 0 && count != 1)
                {
                    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSURLErrorKey: fileURL}];
                    
                    finish();
                    return nil;
                }
                
            } while (result > 0);
            
            short permissions = (info.external_fa >> 16) & 0x01FF;
            if (![self setAttributes:@{NSFilePosixPermissions: @(permissions)} ofItemAtPath:fileURL.path error:error])
            {
                finish();
                return nil;
            }
            
            fclose(outputFile);
            outputFile = NULL;
        }
        
        unzCloseCurrentFile(zipFile);
        
        if (i + 1 < zipInfo.number_entry)
        {
            if (unzGoToNextFile(zipFile) != UNZ_OK)
            {
                *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:@{NSURLErrorKey: fileURL}];
                
                finish();
                return nil;
            }
        }
    }
    
    finish();
    
    if (appBundlePath != nil)
    {
        NSURL *outputURL = [directoryURL URLByAppendingPathComponent:appBundlePath];
        return outputURL;
    }
    else
    {
        *error = [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorMissingAppBundle userInfo:@{NSURLErrorKey: ipaURL}];
        return nil;
    }
}

- (NSURL *)zipAppBundleAtURL:(NSURL *)appBundleURL error:(NSError **)error
{
    NSString *appBundleFilename = [appBundleURL lastPathComponent];
    NSString *appName = [appBundleFilename stringByDeletingPathExtension];
    
    NSString *ipaName = [NSString stringWithFormat:@"%@.ipa", appName];
    NSURL *ipaURL = [[appBundleURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:ipaName];
    
    if ([self fileExistsAtPath:ipaURL.path])
    {
        if (![self removeItemAtURL:ipaURL error:error])
        {
            return nil;
        }
    }
    
    zipFile zipFile = zipOpen(ipaURL.fileSystemRepresentation, APPEND_STATUS_CREATE);
    if (zipFile == nil)
    {
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSURLErrorKey: ipaURL}];
        return nil;
    }
    
    NSURL *payloadDirectory = [NSURL fileURLWithPath:@"Payload" isDirectory:YES];
    NSURL *appBundleDirectory = [payloadDirectory URLByAppendingPathComponent:appBundleFilename isDirectory:YES];
 
    NSDirectoryEnumerator *enumerator = [self enumeratorAtURL:appBundleURL
                                   includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                      options:0
                                                 errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"[Error] %@ (%@)", error, url);
            return NO;
        }
        
        return YES;
    }];
    
    BOOL success = YES;
    
    for (NSURL *fileURL in enumerator)
    {
        NSNumber *isDirectory = nil;
        if (![fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:error])
        {
            success = NO;
            break;
        }
        
        if (![self writeItemAtURL:fileURL toZipFile:&zipFile depth:enumerator.level relativeURL:appBundleDirectory isDirectory:[isDirectory boolValue] error:error])
        {
            success = NO;
            break;
        }
    }
    
    if (success)
    {
        if (![self writeItemAtURL:payloadDirectory toZipFile:&zipFile depth:1 relativeURL:nil isDirectory:YES error:error])
        {
            success = NO;
        }

        if (![self writeItemAtURL:appBundleDirectory toZipFile:&zipFile depth:2 relativeURL:nil isDirectory:YES error:error])
        {
            success = NO;
        }
    }
    
    zipClose(zipFile, NULL);
    
    return success ? ipaURL : nil;
}

- (BOOL)writeItemAtURL:(NSURL *)fileURL toZipFile:(zipFile *)zipFile depth:(NSInteger)depth relativeURL:(nullable NSURL *)relativeURL isDirectory:(BOOL)isDirectory error:(NSError **)error
{
    NSArray<NSString *> *components = fileURL.pathComponents;
    NSArray<NSString *> *relativeComponents = [components subarrayWithRange:NSMakeRange(components.count - depth, depth)];
    
    NSString *relativePath = [relativeComponents componentsJoinedByString:@"/"];
    NSString *filename = nil;
    
    if (relativeURL != nil)
    {
        NSURL *relatedURL = [relativeURL URLByAppendingPathComponent:relativePath];
        filename = relatedURL.relativePath;
    }
    else
    {
        filename = relativePath;
    }
    
    NSData *data = nil;
    zip_fileinfo fileInfo = {};
    
    if (isDirectory)
    {
        if ([filename hasPrefix:@"/"])
        {
            filename = [filename stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        
        if (![filename hasSuffix:@"/"])
        {
            filename = [filename stringByAppendingString:@"/"];
        }
    }
    else
    {
        NSDictionary *attributes = [self attributesOfItemAtPath:fileURL.path error:error];
        if (attributes == nil)
        {
            return NO;
        }
        
        NSNumber *permissionsValue = attributes[NSFilePosixPermissions];
        if (permissionsValue == nil)
        {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:@{NSURLErrorKey: fileURL}];
            return NO;
        }
        
        short permissions = permissionsValue.shortValue;
        NSInteger shiftedPermissions = 0100000 + permissions;
        uLong permissionsLong = @(shiftedPermissions).unsignedLongValue;
        
        fileInfo.external_fa = (unsigned int)(permissionsLong << 16L);
        
        data = [NSData dataWithContentsOfURL:fileURL options:0 error:error];
        if (data == nil)
        {
            return NO;
        }
    }
    
    if (zipOpenNewFileInZip(*zipFile, filename.fileSystemRepresentation, &fileInfo,
                            NULL, 0, NULL, 0, NULL, Z_DEFLATED, Z_DEFAULT_COMPRESSION) != ZIP_OK)
    {
        zipCloseFileInZip(*zipFile);
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSFilePathErrorKey: filename}];
        return NO;
    }
    
    if (zipWriteInFileInZip(*zipFile, data.bytes, (unsigned int)data.length) != ZIP_OK)
    {
        zipCloseFileInZip(*zipFile);
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSFilePathErrorKey: filename}];
        return NO;
    }
    
    return YES;
}

@end
