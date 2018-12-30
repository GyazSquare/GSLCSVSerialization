//
//  GSLCSVSerializationTests.m
//  GSLCSVSerialization
//

@import XCTest;

#import "GSLCSVSerialization.h"

@interface GSLCSVSerializationTests : XCTestCase
@end

@implementation GSLCSVSerializationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testIsValidCSVRecords {
    // nil records
    {
        NSArray *records = nil;
        XCTAssertThrowsSpecificNamed([GSLCSVSerialization isValidCSVRecords:records], NSException, NSInvalidArgumentException);
    }
    // empty records
    {
        NSArray *records = @[];
        XCTAssertFalse([GSLCSVSerialization isValidCSVRecords:records]);
    }
    // empty fields
    {
        NSArray *records = @[@[]];
        XCTAssertFalse([GSLCSVSerialization isValidCSVRecords:records]);
    }
    // wrong field type
    {
        NSArray *records = @[@0];
        XCTAssertFalse([GSLCSVSerialization isValidCSVRecords:records]);
    }
    // wrong record type
    {
        NSArray *records = @[@[@0]];
        XCTAssertFalse([GSLCSVSerialization isValidCSVRecords:records]);
    }
    // different number of fields
    {
        NSArray *records = @[@[@"aaa", @"bbb", @"ccc"], @[@"zzz", @"yyy"]];
        XCTAssertFalse([GSLCSVSerialization isValidCSVRecords:records]);
    }
    // correct records
    {
        NSArray *records = @[@[@"aaa", @"bbb", @"ccc"], @[@"zzz", @"yyy", @"xxx"]];
        XCTAssertTrue([GSLCSVSerialization isValidCSVRecords:records]);
    }
}

- (void)testDataWithCSVRecords {
    // nil records
    {
        NSArray *records = nil;
        NSStringEncoding encoding = NSUTF8StringEncoding;
        GSLCSVWritingOptions opt = 0;
        NSError *error = nil;
        XCTAssertThrowsSpecificNamed([GSLCSVSerialization dataWithCSVRecords:records encoding:encoding options:opt error:&error], NSException, NSInvalidArgumentException);
    }
    // invalid records
    {
        NSArray *records = @[@[]];
        NSStringEncoding encoding = NSUTF8StringEncoding;
        GSLCSVWritingOptions opt = 0;
        NSError *error = nil;
        XCTAssertThrowsSpecificNamed([GSLCSVSerialization dataWithCSVRecords:records encoding:encoding options:opt error:&error], NSException, NSInvalidArgumentException);
    }
    // wrong encoding
    {
        NSArray *records = @[@[@"aaａ", @"bbb", @"ccc"], @[@"zzz", @"yyy", @"xxx"]];
        NSStringEncoding encoding = NSASCIIStringEncoding;
        GSLCSVWritingOptions opt = 0;
        NSError *error = nil;
        NSData *data = [GSLCSVSerialization dataWithCSVRecords:records encoding:encoding options:opt error:&error];
        XCTAssertNil(data);
        XCTAssertEqualObjects(GSLCSVErrorDomain, error.domain);
        XCTAssertEqual(GSLCSVErrorWriteInapplicableStringEncodingError, error.code);
    }
    // empty records
    {
        NSArray *records = @[@[@""]];
        NSData *expected = [NSData data];
        NSStringEncoding encoding = NSUTF8StringEncoding;
        GSLCSVWritingOptions opt = 0;
        NSError *error = nil;
        NSData *data = [GSLCSVSerialization dataWithCSVRecords:records encoding:encoding options:opt error:&error];
        XCTAssertEqualObjects(expected, data);
        XCTAssertNil(error);
    }
    // correct records
    {
        NSArray *records = @[@[@"aaa", @"bbb", @"ccc"], @[@"zzz", @"yyy", @"xxx"]];
        NSData *expected = [@"aaa,bbb,ccc\r\nzzz,yyy,xxx" dataUsingEncoding:NSUTF8StringEncoding];
        NSStringEncoding encoding = NSUTF8StringEncoding;
        GSLCSVWritingOptions opt = 0;
        NSError *error = nil;
        NSData *data = [GSLCSVSerialization dataWithCSVRecords:records encoding:encoding options:opt error:&error];
        XCTAssertEqualObjects(expected, data);
        XCTAssertNil(error);
    }
}

- (void)testWriteCSVRecords {
    // nil records
    {
        NSArray *records = nil;
        NSOutputStream *stream = nil;
        NSStringEncoding encoding = NSUTF8StringEncoding;
        GSLCSVWritingOptions opt = 0;
        NSError *error = nil;
        XCTAssertThrowsSpecificNamed([GSLCSVSerialization writeCSVRecords:records toStream:stream encoding:encoding options:opt error:&error], NSException, NSInvalidArgumentException);
    }
    // invalid records
    {
        NSArray *records = @[@[]];
        NSOutputStream *stream = nil;
        NSStringEncoding encoding = NSUTF8StringEncoding;
        GSLCSVWritingOptions opt = 0;
        NSError *error = nil;
        XCTAssertThrowsSpecificNamed([GSLCSVSerialization writeCSVRecords:records toStream:stream encoding:encoding options:opt error:&error], NSException, NSInvalidArgumentException);
    }
    // nil stream
    {
        NSArray *records = @[@[@""]];
        NSOutputStream *stream = nil;
        NSStringEncoding encoding = NSUTF8StringEncoding;
        GSLCSVWritingOptions opt = 0;
        NSError *error = nil;
        XCTAssertThrowsSpecificNamed([GSLCSVSerialization writeCSVRecords:records toStream:stream encoding:encoding options:opt error:&error], NSException, NSInvalidArgumentException);
    }
    // closed stream
    {
        NSArray *records = @[@[@""]];
        NSOutputStream *stream = [[NSOutputStream alloc] initToMemory];
        NSStringEncoding encoding = NSUTF8StringEncoding;
        GSLCSVWritingOptions opt = 0;
        NSError *error = nil;
        XCTAssertThrowsSpecificNamed([GSLCSVSerialization writeCSVRecords:records toStream:stream encoding:encoding options:opt error:&error], NSException, NSInvalidArgumentException);
    }
    // wrong encoding
    {
        NSArray *records = @[@[@"aaａ", @"bbb", @"ccc"], @[@"zzz", @"yyy", @"xxx"]];
        NSOutputStream *stream = [[NSOutputStream alloc] initToMemory];
        NSStringEncoding encoding = NSASCIIStringEncoding;
        GSLCSVWritingOptions opt = 0;
        NSError *error = nil;
        [stream open];
        NSInteger result = [GSLCSVSerialization writeCSVRecords:records toStream:stream encoding:encoding options:opt error:&error];
        [stream close];
        XCTAssertTrue(result < 0);
        XCTAssertEqualObjects(GSLCSVErrorDomain, error.domain);
        XCTAssertEqual(GSLCSVErrorWriteInapplicableStringEncodingError, error.code);
    }
    // empty records
    {
        NSArray *records = @[@[@""]];
        NSData *expected = [NSData data];
        NSOutputStream *stream = [[NSOutputStream alloc] initToMemory];
        NSStringEncoding encoding = NSUTF8StringEncoding;
        GSLCSVWritingOptions opt = 0;
        NSError *error = nil;
        [stream open];
        NSInteger result = [GSLCSVSerialization writeCSVRecords:records toStream:stream encoding:encoding options:opt error:&error];
        NSData *data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
        [stream close];
        XCTAssertEqual(0, result);
        XCTAssertNil(error);
        XCTAssertEqualObjects(expected, data);
    }
    // empty fields
    {
        NSArray *records = @[@[@"", @"", @""], @[@"", @"", @""]];
        NSData *expected = [@",,\r\n,," dataUsingEncoding:NSUTF8StringEncoding];
        NSOutputStream *stream = [[NSOutputStream alloc] initToMemory];
        NSStringEncoding encoding = NSUTF8StringEncoding;
        GSLCSVWritingOptions opt = 0;
        NSError *error = nil;
        [stream open];
        NSInteger result = [GSLCSVSerialization writeCSVRecords:records toStream:stream encoding:encoding options:opt error:&error];
        NSData *data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
        [stream close];
        XCTAssertTrue(result > 0);
        XCTAssertNil(error);
        XCTAssertEqualObjects(expected, data);
    }
    // 2.1, 2.2 of RFC 4180
    {
        NSArray *records = @[@[@"aaa", @"bbb", @"ccc"], @[@"zzz", @"yyy", @"xxx"]];
        NSData *expected = [@"aaa,bbb,ccc\r\nzzz,yyy,xxx" dataUsingEncoding:NSUTF8StringEncoding];
        NSOutputStream *stream = [[NSOutputStream alloc] initToMemory];
        NSStringEncoding encoding = NSUTF8StringEncoding;
        GSLCSVWritingOptions opt = 0;
        NSError *error = nil;
        [stream open];
        NSInteger result = [GSLCSVSerialization writeCSVRecords:records toStream:stream encoding:encoding options:opt error:&error];
        NSData *data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
        [stream close];
        XCTAssertTrue(result > 0);
        XCTAssertNil(error);
        XCTAssertEqualObjects(expected, data);
    }
    // 2.3 of RFC 4180
    {
        NSArray *records = @[@[@"field_name", @"field_name", @"field_name"], @[@"aaa", @"bbb", @"ccc"], @[@"zzz", @"yyy", @"xxx"]];
        NSData *expected = [@"field_name,field_name,field_name\r\naaa,bbb,ccc\r\nzzz,yyy,xxx" dataUsingEncoding:NSUTF8StringEncoding];
        NSOutputStream *stream = [[NSOutputStream alloc] initToMemory];
        NSStringEncoding encoding = NSUTF8StringEncoding;
        GSLCSVWritingOptions opt = 0;
        NSError *error = nil;
        [stream open];
        NSInteger result = [GSLCSVSerialization writeCSVRecords:records toStream:stream encoding:encoding options:opt error:&error];
        NSData *data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
        [stream close];
        XCTAssertTrue(result > 0);
        XCTAssertNil(error);
        XCTAssertEqualObjects(expected, data);
    }
    // 2.4 of RFC 4180
    {
        NSArray *records = @[@[@"aaa", @"bbb", @"ccc"]];
        NSData *expected = [@"aaa,bbb,ccc" dataUsingEncoding:NSUTF8StringEncoding];
        NSOutputStream *stream = [[NSOutputStream alloc] initToMemory];
        NSStringEncoding encoding = NSUTF8StringEncoding;
        GSLCSVWritingOptions opt = 0;
        NSError *error = nil;
        [stream open];
        NSInteger result = [GSLCSVSerialization writeCSVRecords:records toStream:stream encoding:encoding options:opt error:&error];
        NSData *data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
        [stream close];
        XCTAssertTrue(result > 0);
        XCTAssertNil(error);
        XCTAssertEqualObjects(expected, data);
    }
    // 2.5 of RFC 4180
    {
        NSArray *records = @[@[@"aaa", @"bbb", @"ccc"], @[@"zzz", @"yyy", @"xxx"]];
        NSData *expected = [@"\"aaa\",\"bbb\",\"ccc\"\r\n\"zzz\",\"yyy\",\"xxx\"" dataUsingEncoding:NSUTF8StringEncoding];
        NSOutputStream *stream = [[NSOutputStream alloc] initToMemory];
        NSStringEncoding encoding = NSUTF8StringEncoding;
        GSLCSVWritingOptions opt = GSLCSVWritingEscapeAllFields;
        NSError *error = nil;
        [stream open];
        NSInteger result = [GSLCSVSerialization writeCSVRecords:records toStream:stream encoding:encoding options:opt error:&error];
        NSData *data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
        [stream close];
        XCTAssertTrue(result > 0);
        XCTAssertNil(error);
        XCTAssertEqualObjects(expected, data);
    }
    // 2.6 of RFC 4180
    {
        NSArray *records = @[@[@"aaa", @"b\r\nbb", @"ccc"], @[@"zzz", @"yyy", @"xxx"]];
        NSData *expected = [@"aaa,\"b\r\nbb\",ccc\r\nzzz,yyy,xxx" dataUsingEncoding:NSUTF8StringEncoding];
        NSOutputStream *stream = [[NSOutputStream alloc] initToMemory];
        NSStringEncoding encoding = NSUTF8StringEncoding;
        GSLCSVWritingOptions opt = 0;
        NSError *error = nil;
        [stream open];
        NSInteger result = [GSLCSVSerialization writeCSVRecords:records toStream:stream encoding:encoding options:opt error:&error];
        NSData *data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
        [stream close];
        XCTAssertTrue(result > 0);
        XCTAssertNil(error);
        XCTAssertEqualObjects(expected, data);
    }
    // 2.7 of RFC 4180
    {
        NSArray *records = @[@[@"aaa", @"b\"bb", @"ccc"]];
        NSData *expected = [@"aaa,\"b\"\"bb\",ccc" dataUsingEncoding:NSUTF8StringEncoding];
        NSOutputStream *stream = [[NSOutputStream alloc] initToMemory];
        NSStringEncoding encoding = NSUTF8StringEncoding;
        GSLCSVWritingOptions opt = 0;
        NSError *error = nil;
        [stream open];
        NSInteger result = [GSLCSVSerialization writeCSVRecords:records toStream:stream encoding:encoding options:opt error:&error];
        NSData *data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
        [stream close];
        XCTAssertTrue(result > 0);
        XCTAssertNil(error);
        XCTAssertEqualObjects(expected, data);
    }
}

- (void)testCSVRecordsWithData {
    // nil data
    {
        NSData *data = nil;
        XCTAssertThrowsSpecificNamed([GSLCSVSerialization CSVRecordsWithData:data encoding:NSUTF8StringEncoding options:0 error:NULL], NSException, NSInvalidArgumentException);
    }
    // wrong encoding
    {
        NSString *string = @"aaa,bbb,ccc\r\nzzz,yyy,xxx\r\n";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:NSUTF32StringEncoding options:0 error:&error];
        XCTAssertNil(records);
        XCTAssertEqualObjects(GSLCSVErrorDomain, error.domain);
        XCTAssertEqual(GSLCSVErrorReadInapplicableStringEncodingError, error.code);
    }
    // wrong escaped (1)
    {
        NSString *string = @"\"aaa\",\"bbb\",\"ccc\r\nzzz,yyy,xxx\r\n";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:NSUTF8StringEncoding options:0 error:&error];
        XCTAssertNil(records);
        XCTAssertEqualObjects(GSLCSVErrorDomain, error.domain);
        XCTAssertEqual(GSLCSVErrorReadCorrupt, error.code);
    }
    // wrong escaped (2)
    {
        NSString *string = @"\"aaa\",\"b\"\"bb,\"ccc\"";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:NSUTF8StringEncoding options:0 error:&error];
        XCTAssertNil(records);
        XCTAssertEqualObjects(GSLCSVErrorDomain, error.domain);
        XCTAssertEqual(GSLCSVErrorReadCorrupt, error.code);
    }
    // empty data
    {
        NSString *string = @"";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:NSUTF8StringEncoding options:0 error:&error];
        NSArray *expected = @[@[@""]];
        XCTAssertEqualObjects(expected, records);
        XCTAssertNil(error);
    }
    // empty fields
    {
        NSString *string = @",,\r\n,,";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:NSUTF8StringEncoding options:0 error:&error];
        NSArray *expected = @[@[@"", @"", @""], @[@"", @"", @""]];
        XCTAssertEqualObjects(expected, records);
        XCTAssertNil(error);
    }
    // 2.1 of RFC 4180 (line break: CRLF)
    {
        NSString *string = @"aaa,bbb,ccc\r\nzzz,yyy,xxx\r\n";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:NSUTF8StringEncoding options:0 error:&error];
        NSArray *expected = @[@[@"aaa", @"bbb", @"ccc"], @[@"zzz", @"yyy", @"xxx"]];
        XCTAssertEqualObjects(expected, records);
        XCTAssertNil(error);
    }
    // 2.1 of RFC 4180 (line break: CR)
    {
        NSString *string = @"aaa,bbb,ccc\rzzz,yyy,xxx\r";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:NSUTF8StringEncoding options:0 error:&error];
        NSArray *expected = @[@[@"aaa", @"bbb", @"ccc"], @[@"zzz", @"yyy", @"xxx"]];
        XCTAssertEqualObjects(expected, records);
        XCTAssertNil(error);
    }
    // 2.1 of RFC 4180 (line break: LF)
    {
        NSString *string = @"aaa,bbb,ccc\nzzz,yyy,xxx\n";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:NSUTF8StringEncoding options:0 error:&error];
        NSArray *expected = @[@[@"aaa", @"bbb", @"ccc"], @[@"zzz", @"yyy", @"xxx"]];
        XCTAssertEqualObjects(expected, records);
        XCTAssertNil(error);
    }
    // 2.2 of RFC 4180
    {
        NSString *string = @"aaa,bbb,ccc\r\nzzz,yyy,xxx";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:NSUTF8StringEncoding options:0 error:&error];
        NSArray *expected = @[@[@"aaa", @"bbb", @"ccc"], @[@"zzz", @"yyy", @"xxx"]];
        XCTAssertEqualObjects(expected, records);
        XCTAssertNil(error);
    }
    // 2.3 of RFC 4180
    {
        NSString *string = @"field_name,field_name,field_name\r\naaa,bbb,ccc\r\nzzz,yyy,xxx\r\n";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:NSUTF8StringEncoding options:0 error:&error];
        NSArray *expected = @[@[@"field_name", @"field_name", @"field_name"], @[@"aaa", @"bbb", @"ccc"], @[@"zzz", @"yyy", @"xxx"]];
        XCTAssertEqualObjects(expected, records);
        XCTAssertNil(error);
    }
    // 2.4 of RFC 4180
    {
        NSString *string = @"aaa,bbb,ccc";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:NSUTF8StringEncoding options:0 error:&error];
        NSArray *expected = @[@[@"aaa", @"bbb", @"ccc"]];
        XCTAssertEqualObjects(expected, records);
        XCTAssertNil(error);
    }
    // 2.5 of RFC 4180
    {
        NSString *string = @"\"aaa\",\"bbb\",\"ccc\"\r\nzzz,yyy,xxx";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:NSUTF8StringEncoding options:0 error:&error];
        NSArray *expected = @[@[@"aaa", @"bbb", @"ccc"], @[@"zzz", @"yyy", @"xxx"]];
        XCTAssertEqualObjects(expected, records);
        XCTAssertNil(error);
    }
    // 2.6 of RFC 4180
    {
        NSString *string = @"\"aaa\",\"b\r\nbb\",\"ccc\"\r\nzzz,yyy,xxx";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:NSUTF8StringEncoding options:0 error:&error];
        NSArray *expected = @[@[@"aaa", @"b\r\nbb", @"ccc"], @[@"zzz", @"yyy", @"xxx"]];
        XCTAssertEqualObjects(expected, records);
        XCTAssertNil(error);
    }
    // 2.7 of RFC 4180
    {
        NSString *string = @"\"aaa\",\"b\"\"bb\",\"ccc\"";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:NSUTF8StringEncoding options:0 error:&error];
        NSArray *expected = @[@[@"aaa", @"b\"bb", @"ccc"]];
        XCTAssertEqualObjects(expected, records);
        XCTAssertNil(error);
    }
    // GSLCSVReadingMutableContainers
    {
        NSString *string = @"aaa,bbb,ccc\r\nzzz,yyy,xxx\r\n";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:NSUTF8StringEncoding options:GSLCSVReadingMutableContainers error:&error];
        for (NSMutableArray *fields in records) {
            XCTAssertNoThrow([fields removeAllObjects]);
        }
        XCTAssertNoThrow([(NSMutableArray *)records removeAllObjects]);
    }
    // GSLCSVReadingMutableLeaves
    {
        NSString *string = @"aaa,bbb,ccc\r\nzzz,yyy,xxx\r\n";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:NSUTF8StringEncoding options:GSLCSVReadingMutableLeaves error:&error];
        for (NSArray *fields in records) {
            for (NSMutableString *field in fields) {
                [field replaceCharactersInRange:NSMakeRange(0, field.length) withString:@""];
            }
        }
    }
}

- (void)testCSVRecordsWithStream {
    // nil stream
    {
        NSInputStream *stream = nil;
        XCTAssertThrowsSpecificNamed([GSLCSVSerialization CSVRecordsWithStream:stream encoding:NSUTF8StringEncoding options:0 error:NULL], NSException, NSInvalidArgumentException);
    }
    // 2.1 of RFC 4180
    {
        NSString *string = @"aaa,bbb,ccc\r\nzzz,yyy,xxx\r\n";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSInputStream *stream = [[NSInputStream alloc] initWithData:data];
        NSError *error = nil;
        [stream open];
        NSArray *records = [GSLCSVSerialization CSVRecordsWithStream:stream encoding:NSUTF8StringEncoding options:0 error:&error];
        [stream close];
        NSArray *expected = @[@[@"aaa", @"bbb", @"ccc"], @[@"zzz", @"yyy", @"xxx"]];
        XCTAssertEqualObjects(expected, records);
        XCTAssertNil(error);
    }
}

#if 0
- (void)testPerformanceCSVRecordsWithData {
    NSString *path = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"KEN_ALL.CSV"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese);
    [self measureBlock:^{
        NSError *error = nil;
        NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:encoding options:0 error:&error];
        if (!records) {
            NSLog(@"%@", error);
        }
    }];
}
#endif

#if 0
- (void)testPerformanceDataWithCSVRecords {
    NSString *path = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"KEN_ALL.CSV"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese);
    NSError *error = nil;
    NSArray *records = [GSLCSVSerialization CSVRecordsWithData:data encoding:encoding options:0 error:&error];
    if (!records) {
        NSLog(@"%@", error);
        return;
    }
    [self measureBlock:^{
        NSError *error = nil;
        NSData *data = [GSLCSVSerialization dataWithCSVRecords:records encoding:encoding options:0 error:&error];
        if (!data) {
            NSLog(@"%@", error);
            return;
        }
    }];
}
#endif

@end
