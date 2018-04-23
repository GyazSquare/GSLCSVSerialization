//
//  GSLCSVSerialization.m
//  GSLCSVSerialization
//

@import Foundation;

#import "GSLCSVSerialization.h"

#define kDQUOTE         @"\x22"
#define k2DQUOTE        @"\x22\x22"
#define kCOMMA          @"\x2C"
#define kCR             @"\x0D"
#define kLF             @"\x0A"
#define kCRLF           @"\x0D\x0A"
#define kFieldSeparator @"\x2C\x0D\x0A"
#define kNonTextData    @"\x2C\x0D\x0A\x22"

#define kDQUOTECharacter 0x22

static BOOL __GSLCSVIsValidCSVRecords(NSArray<NSArray<NSString *> *> *records, NSString **errorString) {
    if (records.count == 0) {
        if (errorString) {
            *errorString = @"records count is zero";
        }
        return NO;
    }
    NSUInteger fieldCount = 0;
    for (NSArray<NSString *> *fields in records) {
        if (![fields isKindOfClass:[NSArray class]]) {
            if (errorString) {
                *errorString = [NSString stringWithFormat:@"invalid record type (%@)", [fields class]];
            }
            return NO;
        }
        if (fieldCount == 0) {
            fieldCount = fields.count;
            if (fieldCount == 0) {
                if (errorString) {
                    *errorString = @"number of fields is zero";
                }
                return NO;
            }
        } else {
            if (fieldCount != fields.count) {
                if (errorString) {
                    *errorString = @"each record should contain the same number of fields";
                }
                return NO;
            }
        }
        for (NSString *field in fields) {
            if (![field isKindOfClass:[NSString class]]) {
                if (errorString) {
                    *errorString = [NSString stringWithFormat:@"invalid field type (%@)", [field class]];
                }
                return NO;
            }
        }
    }
    return YES;
}

static BOOL __GSLCSVShouldEscapeField(NSString *field) {
    static NSCharacterSet *nonTextDataCharacterSet = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        nonTextDataCharacterSet = [NSCharacterSet characterSetWithCharactersInString:kNonTextData];
    });
    return ([field rangeOfCharacterFromSet:nonTextDataCharacterSet options:NSLiteralSearch].location != NSNotFound);
}

static NSString * __GSLCSVCopyEscapedField(NSString *field) NS_RETURNS_RETAINED {
    NSMutableString *escaped = [NSMutableString new];
    [escaped appendString:kDQUOTE];
    NSRange searchRange = NSMakeRange(0, field.length);
    while (searchRange.location < field.length) {
        NSRange doubleQuoteRange = [field rangeOfString:kDQUOTE options:NSLiteralSearch range:searchRange];
        if (doubleQuoteRange.location == NSNotFound) {
            [escaped appendString:[field substringWithRange:searchRange]];
            break;
        }
        NSRange range = NSMakeRange(searchRange.location, doubleQuoteRange.location - searchRange.location);
        [escaped appendString:[field substringWithRange:range]];
        [escaped appendString:k2DQUOTE];
        searchRange = NSMakeRange(NSMaxRange(doubleQuoteRange), field.length - NSMaxRange(doubleQuoteRange));
    }
    [escaped appendString:kDQUOTE];
    return escaped;
}

static NSInteger __GSLCSVWriteRecord(NSOutputStream *stream, NSArray<NSString *> *fields, NSStringEncoding encoding, GSLCSVWritingOptions opt, NSError **outError) {
    NSUInteger fieldCount = fields.count;
    NSInteger result = 0;
    for (NSUInteger i = 0; i < fieldCount; i++) {
        if (i > 0) {
            const char *comma = ",";
            size_t commaLength = strlen(comma);
            NSInteger bytesWritten = [stream write:(uint8_t *)comma maxLength:commaLength];
            if (bytesWritten <= 0) {
                if (outError) {
                    NSError *error;
                    if (bytesWritten < 0) {
                        error = stream.streamError;
                    } else {
                        error = [NSError errorWithDomain:NSPOSIXErrorDomain code:EPIPE userInfo:nil];
                    }
                    NSDictionary *userInfo = @{NSUnderlyingErrorKey: error};
                    *outError = [NSError errorWithDomain:GSLCSVErrorDomain code:GSLCSVErrorWriteStreamError userInfo:userInfo];
                }
                return -1;
            } else {
                result += bytesWritten;
            }
        }
        NSString *field = ^{
            if (@available(macOS 10.8, *)) {
                // macOS 10.8+
                return fields[i];
            } else {
                // macOS 10.6-10.8
                return [fields objectAtIndex:i];
            }
        }();
        if (field.length == 0) {
            continue;
        }
        if ((opt & GSLCSVWritingEscapeAllFields)
            || __GSLCSVShouldEscapeField(field)) {
            field = __GSLCSVCopyEscapedField(field);
        }
        NSUInteger maxLength = [field maximumLengthOfBytesUsingEncoding:encoding];
        char buffer[maxLength];
        NSUInteger usedLength = 0;
        NSRange remainingRange = NSMakeRange(NSNotFound, 0);
        if (![field getBytes:buffer maxLength:maxLength usedLength:&usedLength encoding:encoding options:0 range:NSMakeRange(0, field.length) remainingRange:&remainingRange] || remainingRange.length != 0) {
            if (outError) {
                NSString *description = [NSString stringWithFormat:NSLocalizedString(@"The string couldn’t be converted to the text encoding %@.", @""), [NSString localizedNameOfStringEncoding:encoding]];
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: description, NSStringEncodingErrorKey: @(encoding)};
                *outError = [NSError errorWithDomain:GSLCSVErrorDomain code:GSLCSVErrorWriteInapplicableStringEncodingError userInfo:userInfo];
            }
            return -1;
        }
        NSInteger bytesWritten = [stream write:(uint8_t *)buffer maxLength:usedLength];
        if (bytesWritten <= 0) {
            if (outError) {
                NSError *error;
                if (bytesWritten < 0) {
                    error = stream.streamError;
                } else {
                    error = [NSError errorWithDomain:NSPOSIXErrorDomain code:EPIPE userInfo:nil];
                }
                NSDictionary *userInfo = @{NSUnderlyingErrorKey: error};
                *outError = [NSError errorWithDomain:GSLCSVErrorDomain code:GSLCSVErrorWriteStreamError userInfo:userInfo];
            }
            return -1;
        } else {
            result += bytesWritten;
        }
    }
    return result;
}

static NSInteger __GSLCSVWriteLineBreak(NSOutputStream *stream, NSError **outError) {
    const char *lineBreak = "\r\n";
    size_t lineBreakLength = strlen(lineBreak);
    NSInteger bytesWritten = [stream write:(uint8_t *)lineBreak maxLength:lineBreakLength];
    if (bytesWritten <= 0) {
        if (outError) {
            NSError *error;
            if (bytesWritten < 0) {
                error = stream.streamError;
            } else {
                error = [NSError errorWithDomain:NSPOSIXErrorDomain code:EPIPE userInfo:nil];
            }
            NSDictionary *userInfo = @{NSUnderlyingErrorKey: error};
            *outError = [NSError errorWithDomain:GSLCSVErrorDomain code:GSLCSVErrorWriteStreamError userInfo:userInfo];
        }
        return -1;
    } else {
        return bytesWritten;
    }
}

static BOOL __GSLCSVScanEscaped(NSScanner *scanner, GSLCSVReadingOptions opt, NSString **outEscaped, NSError **outError) {
    NSUInteger startLocation = scanner.scanLocation;
    if (![scanner scanString:kDQUOTE intoString:NULL]) {
        [NSException raise:NSInternalInconsistencyException format:@"*** %s: a escaped field must start with a double-quote", __PRETTY_FUNCTION__];
    }
    NSString *result = nil;
    for (;;) {
        NSString *partialString = @"";
        [scanner scanUpToString:kDQUOTE intoString:&partialString];
        if (![scanner scanString:kDQUOTE intoString:NULL]) {
            if (outError) {
                NSString *description = NSLocalizedString(@"The data couldn’t be read because it isn’t in the correct format.", @"");
                NSString *debugDescription = [NSString stringWithFormat:NSLocalizedString(@"Invalid escaped field around character %lu", @""), (unsigned long)startLocation];
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: description, @"NSDebugDescription": debugDescription};
                *outError = [NSError errorWithDomain:GSLCSVErrorDomain code:GSLCSVErrorReadCorrupt userInfo:userInfo];
            }
            return NO;
        }
        if (!result) {
            result = partialString;
        } else {
            result = [result stringByAppendingString:partialString];
        }
        if (![scanner scanString:kDQUOTE intoString:NULL]) {
            break;
        }
        // 2DQUOTE
        result = [result stringByAppendingString:kDQUOTE];
    }
    if (outEscaped) {
        if (opt & GSLCSVReadingMutableLeaves) {
            *outEscaped = [result mutableCopy];
        } else {
            *outEscaped = result;
        }
    }
    return YES;
}

static BOOL __GSLCSVScanNonEscaped(NSScanner *scanner, GSLCSVReadingOptions opt, NSString **outNonEscaped, NSError **outError) {
    static NSCharacterSet *fieldSeparatorCharacterSet = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        fieldSeparatorCharacterSet = [NSCharacterSet characterSetWithCharactersInString:kFieldSeparator];
    });
    NSString *result = @"";
    [scanner scanUpToCharactersFromSet:fieldSeparatorCharacterSet intoString:&result];
    if (outNonEscaped) {
        if (opt & GSLCSVReadingMutableLeaves) {
            *outNonEscaped = [result mutableCopy];
        } else {
            *outNonEscaped = result;
        }
    }
    return YES;
}

static BOOL __GSLCSVScanField(NSScanner *scanner, GSLCSVReadingOptions opt, NSString **outField, NSError **outError) {
    if (scanner.atEnd) {
        if (outField) {
            if (opt & GSLCSVReadingMutableLeaves) {
                *outField = [NSMutableString new];
            } else {
                *outField = @"";
            }
        }
        return YES;
    } else {
        unichar c = [scanner.string characterAtIndex:scanner.scanLocation];
        if (c == kDQUOTECharacter) {
            return __GSLCSVScanEscaped(scanner, opt, outField, outError);
        } else {
            return __GSLCSVScanNonEscaped(scanner, opt, outField, outError);
        }
    }
}

static BOOL __GSLCSVScanRecord(NSScanner *scanner, GSLCSVReadingOptions opt, NSArray<NSString *> **outFields, NSError **outError) {
    NSMutableArray<NSString *> *fields = [NSMutableArray new];
    NSString *field = nil;
    NSError *error = nil;
    while (__GSLCSVScanField(scanner, opt, &field, &error)) {
        [fields addObject:field];
        if (![scanner scanString:kCOMMA intoString:NULL]) {
            break;
        }
    }
    if (error) {
        if (outError) {
            *outError = error;
        }
        return NO;
    } else {
        if (outFields) {
            if (opt & GSLCSVReadingMutableContainers) {
                *outFields = fields;
            } else {
                *outFields = [fields copy];
            }
        }
        return YES;
    }
}

static BOOL __GSLCSVScanLineBreak(NSScanner *scanner, NSString **result) {
    return ([scanner scanString:kCRLF intoString:result]
            || [scanner scanString:kCR intoString:result]
            || [scanner scanString:kLF intoString:result]);
}

static BOOL __GSLCSVConvertInputStreamToBytes(NSInputStream *stream, void **bytes, NSUInteger *length, NSError **error) {
    uint8_t *buf = NULL, sbuf[8192];
    NSUInteger buflen = 0, bufsize = 0;
    for (;;) {
        NSInteger retlen = [stream read:sbuf maxLength:8192];
        if (retlen <= 0) {
            if (retlen < 0) {
                if (buf) {
                    NSZoneFree(NULL, buf);
                    buf = NULL;
                }
                buflen = 0;
                if (error) {
                    *error = stream.streamError;
                }
            }
            if (bytes) {
                *bytes = buf;
            }
            if (length) {
                *length = buflen;
            }
            return (retlen == 0);
        }
        if (bufsize < buflen + retlen) {
            if (bufsize < 256 * 1024) {
                bufsize *= 4;
            } else if (bufsize < 16 * 1024 * 1024) {
                bufsize *= 2;
            } else {
                bufsize += 256 * 1024;
            }
            if (bufsize < buflen + retlen) {
                bufsize = buflen + retlen;
            }
            buf = NSZoneRealloc(NULL, buf, bufsize);
        }
        memmove(buf + buflen, sbuf, retlen);
        buflen += retlen;
    }
    return YES;
}

NSString * const GSLCSVErrorDomain = @"GSLCSVErrorDomain";

@implementation GSLCSVSerialization

+ (BOOL)isValidCSVRecords:(nullable NSArray<NSArray<NSString *> *> *)records {
    return __GSLCSVIsValidCSVRecords(records, NULL);
}

+ (nullable NSData *)dataWithCSVRecords:(NSArray<NSArray<NSString *> *> *)records encoding:(NSStringEncoding)encoding options:(GSLCSVWritingOptions)opt error:(NSError **)outError {
    if (!records) {
        [NSException raise:NSInvalidArgumentException format:@"*** %s: records parameter is nil", __PRETTY_FUNCTION__];
    }
    NSString *errorString = nil;
    if (!__GSLCSVIsValidCSVRecords(records, &errorString)) {
        [NSException raise:NSInvalidArgumentException format:@"*** %s: %@", __PRETTY_FUNCTION__, errorString];
    }
    NSOutputStream *stream = [[NSOutputStream alloc] initToMemory];
    [stream open];
    NSData *data;
    if ([self writeCSVRecords:records toStream:stream encoding:encoding options:opt error:outError] >= 0) {
        data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    } else {
        data = nil;
    }
    [stream close];
    return data;
}

+ (NSInteger)writeCSVRecords:(NSArray<NSArray<NSString *> *> *)records toStream:(NSOutputStream *)stream encoding:(NSStringEncoding)encoding options:(GSLCSVWritingOptions)opt error:(NSError **)outError {
    if (!records) {
        [NSException raise:NSInvalidArgumentException format:@"*** %s: records parameter is nil", __PRETTY_FUNCTION__];
    }
    NSString *errorString = nil;
    if (!__GSLCSVIsValidCSVRecords(records, &errorString)) {
        [NSException raise:NSInvalidArgumentException format:@"*** %s: %@", __PRETTY_FUNCTION__, errorString];
    }
    if (!stream) {
        [NSException raise:NSInvalidArgumentException format:@"*** %s: stream parameter is nil", __PRETTY_FUNCTION__];
    }
    if ((stream.streamStatus != NSStreamStatusOpen)
        && (stream.streamStatus != NSStreamStatusWriting)) {
        [NSException raise:NSInvalidArgumentException format:@"*** %s: stream is not open for writing", __PRETTY_FUNCTION__];
    }
    NSInteger result = 0;
    for (NSUInteger i = 0; i < records.count; i++) {
        if (i > 0) {
            NSError *error = nil;
            NSInteger bytesWritten = __GSLCSVWriteLineBreak(stream, &error);
            if (bytesWritten < 0) {
                if (outError) {
                    *outError = error;
                }
                return -1;
            } else {
                result += bytesWritten;
            }
        }
        NSArray<NSString *> *fields = ^{
            if (@available(macOS 10.8, *)) {
                // macOS 10.8+
                return records[i];
            } else {
                // macOS 10.6-10.8
                return [records objectAtIndex:i];
            }
        }();
        NSError *error = nil;
        NSInteger bytesWritten = __GSLCSVWriteRecord(stream, fields, encoding, opt, &error);
        if (bytesWritten < 0) {
            if (outError) {
                *outError = error;
            }
            return -1;
        } else {
            result += bytesWritten;
        }
    }
    return result;
}

+ (nullable __kindof NSArray<__kindof NSArray<__kindof NSString *> *> *)CSVRecordsWithData:(NSData *)data encoding:(NSStringEncoding)encoding options:(GSLCSVReadingOptions)opt error:(NSError **)outError {
    if (!data) {
        [NSException raise:NSInvalidArgumentException format:@"*** %s: data parameter is nil", __PRETTY_FUNCTION__];
    }
    NSString *string = [[NSString alloc] initWithData:data encoding:encoding];
    if (!string) {
        if (outError) {
            NSString *description = [NSString stringWithFormat:NSLocalizedString(@"The data couldn’t be converted into Unicode characters using text encoding %@.", @""), [NSString localizedNameOfStringEncoding:encoding]];
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: description, NSStringEncodingErrorKey: @(encoding)};
            *outError = [NSError errorWithDomain:GSLCSVErrorDomain code:GSLCSVErrorReadInapplicableStringEncodingError userInfo:userInfo];
        }
        return nil;
    }
    NSScanner *scanner = [[NSScanner alloc] initWithString:string];
    scanner.charactersToBeSkipped = nil;
    NSMutableArray<NSArray<NSString *> *> *records = [NSMutableArray new];
    NSError *error = nil;
    do {
        @autoreleasepool {
            NSArray<NSString *> *fields = nil;
            if (!__GSLCSVScanRecord(scanner, opt, &fields, &error)) {
                break;
            }
            [records addObject:fields];
            if (!__GSLCSVScanLineBreak(scanner, NULL)) {
                if (!scanner.atEnd) {
                    NSString *description = NSLocalizedString(@"The data couldn’t be read because it isn’t in the correct format.", @"");
                    NSString *debugDescription = NSLocalizedString(@"Garbage at end.", @"");
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: description, @"NSDebugDescription": debugDescription};
                    error = [NSError errorWithDomain:GSLCSVErrorDomain code:GSLCSVErrorReadCorrupt userInfo:userInfo];
                }
                break;
            }
        }
    } while (!scanner.atEnd);
    if (error) {
        if (outError) {
            *outError = error;
        }
        return nil;
    } else {
        if (opt & GSLCSVReadingMutableContainers) {
            return records;
        } else {
            return [records copy];
        }
    }
}

+ (nullable __kindof NSArray<__kindof NSArray<__kindof NSString *> *> *)CSVRecordsWithStream:(NSInputStream *)stream encoding:(NSStringEncoding)encoding options:(GSLCSVReadingOptions)opt error:(NSError **)outError {
    if (!stream) {
        [NSException raise:NSInvalidArgumentException format:@"*** %s: stream parameter is nil", __PRETTY_FUNCTION__];
    }
    if ((stream.streamStatus != NSStreamStatusOpen)
        && ([stream streamStatus] != NSStreamStatusReading)) {
        [NSException raise:NSInvalidArgumentException format:@"*** %s: stream is not open for reading", __PRETTY_FUNCTION__];
    }
    void *bytes = NULL;
    NSUInteger length = 0;
    NSError *error = nil;
    if (!__GSLCSVConvertInputStreamToBytes(stream, &bytes, &length, &error)) {
        if (outError) {
            NSDictionary *userInfo = nil;
            if (error) {
                userInfo = @{NSUnderlyingErrorKey: error};
            }
            *outError = [NSError errorWithDomain:GSLCSVErrorDomain code:GSLCSVErrorReadStreamError userInfo:userInfo];
        }
        return nil;
    }
    NSData *data = [[NSData alloc] initWithBytesNoCopy:bytes length:length];
    return [self CSVRecordsWithData:data encoding:encoding options:opt error:outError];
}

@end
