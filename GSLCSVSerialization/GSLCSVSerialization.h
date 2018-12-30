//
//  GSLCSVSerialization.h
//  GSLCSVSerialization
//

@import Foundation.NSObject;
@import Foundation.NSString;

NS_ASSUME_NONNULL_BEGIN

@class NSArray, NSData, NSError, NSInputStream, NSOutputStream;

FOUNDATION_EXPORT NSString * const GSLCSVErrorDomain;

typedef NS_ENUM(NSInteger, GSLCSVErrorCode) {
    GSLCSVErrorUnknown = 0,
    GSLCSVErrorReadInapplicableStringEncodingError = 1,
    GSLCSVErrorReadCorrupt = 2,
    GSLCSVErrorReadStreamError = 3,
    GSLCSVErrorWriteInapplicableStringEncodingError = 4,
    GSLCSVErrorWriteStreamError = 5
};

typedef NS_OPTIONS(NSUInteger, GSLCSVReadingOptions) {
    GSLCSVReadingMutableContainers NS_SWIFT_UNAVAILABLE("Mutability options not available") = (1UL << 0),
    GSLCSVReadingMutableLeaves NS_SWIFT_UNAVAILABLE("Mutability options not available") = (1UL << 1)
};

typedef NS_OPTIONS(NSUInteger, GSLCSVWritingOptions) {
    GSLCSVWritingEscapeAllFields = (1UL << 0)
};

@interface GSLCSVSerialization : NSObject

+ (BOOL)isValidCSVRecords:(NSArray<NSArray<NSString *> *> *)records;

+ (nullable NSData *)dataWithCSVRecords:(NSArray<NSArray<NSString *> *> *)records encoding:(NSStringEncoding)encoding options:(GSLCSVWritingOptions)opt error:(NSError **)error;
+ (NSInteger)writeCSVRecords:(NSArray<NSArray<NSString *> *> *)records toStream:(NSOutputStream *)stream encoding:(NSStringEncoding)encoding options:(GSLCSVWritingOptions)opt error:(NSError **)error;

+ (nullable __kindof NSArray<__kindof NSArray<__kindof NSString *> *> *)CSVRecordsWithData:(NSData *)data encoding:(NSStringEncoding)encoding options:(GSLCSVReadingOptions)opt error:(NSError **)error;
+ (nullable __kindof NSArray<__kindof NSArray<__kindof NSString *> *> *)CSVRecordsWithStream:(NSInputStream *)stream encoding:(NSStringEncoding)encoding options:(GSLCSVReadingOptions)opt error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
