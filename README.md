# GSLCSVSerialization

[![Build Status](https://travis-ci.org/GyazSquare/GSLCSVSerialization.svg?branch=master)](https://travis-ci.org/GyazSquare/GSLCSVSerialization)

GSLCSVSerialization is an Objective-C CSV parser for iOS, OS X, watchOS and tvOS.

## Requirements

* Xcode 9.0 or later
* Base SDK: iOS 11.0 / OS X 10.13 / watchOS 4.0 / tvOS 11.0 or later
* Deployment Target: iOS 8.0 / OS X 10.6 / watchOS 2.0 / tvOS 9.0  or later

## Installation

### CocoaPods

Add the pod to your `Podfile`:

```ruby
# ...

pod 'GSLCSVSerialization'
```

Install the pod:

```shell
$ pod install
```

### Source

Check out the source:

```shell
$ git clone https://github.com/GyazSquare/GSLCSVSerialization.git
```

## Usage

### Creating a CSV Object

GSLCSVSerialization can create a CSV object from a [RFC 4180](https://tools.ietf.org/html/rfc4180)-compliant CSV data by using the following methods:

```objective-c
+ (nullable __kindof NSArray<__kindof NSArray<__kindof NSString *> *> *)CSVRecordsWithData:(NSData *)data encoding:(NSStringEncoding)encoding options:(GSLCSVReadingOptions)opt error:(NSError **)error;
+ (nullable __kindof NSArray<__kindof NSArray<__kindof NSString *> *> *)CSVRecordsWithStream:(NSInputStream *)stream encoding:(NSStringEncoding)encoding options:(GSLCSVReadingOptions)opt error:(NSError **)error;
```

For example, if you parse CSV data below,

```text
aaa,bbb,ccc
zzz,yyy,xxx
```

you can get a CSV object like this:

```objective-c
@[
    @[@"aaa",@"bbb",@"ccc"],
    @[@"zzz",@"yyy",@"xxx"]
]
```

### Creating CSV Data

GSLCSVSerialization can create CSV data from a CSV object by using the following methods:

```objective-c
+ (nullable NSData *)dataWithCSVRecords:(NSArray<NSArray<NSString *> *> *)records encoding:(NSStringEncoding)encoding options:(GSLCSVWritingOptions)opt error:(NSError **)error;
+ (NSInteger)writeCSVRecords:(NSArray<NSArray<NSString *> *> *)records toStream:(NSOutputStream *)stream encoding:(NSStringEncoding)encoding options:(GSLCSVWritingOptions)opt error:(NSError **)error;
```

A `records` object is a two-dimensional array containing `field` strings. You should check whether the input will produce valid CSV data before calling these methods by using `isValidCSVRecords:`.

## License

This software is licensed under the MIT License.

See the LICENSE file for details.
