//
//  NSObject+HDeserializable.h
//  HAccess
//
//  Created by zct on 2019/2/15.
//  Copyright © 2019 zhangchutian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HPropertyMgr.h"
#import <Hodor/HCommon.h>
#import <Hodor/NSObject+annotation.h>

NS_ASSUME_NONNULL_BEGIN
//safe get property name
#define pp_name(k) (self.k?@#k:@#k)

#pragma mark - annotion keys

//ignore property
#define HPIgnore @"ignore"

//property could be nil
#define HPOptional @"optional"

//property map to another key name
#define HPMapto(s) @{@"mapto":s}

//autocast between NSNumber and NSString
#define HPAutoCast @"autocast"

//value scope, only use for NSNumber
#define HPScope(from,to) @{@"scope":@{@"from":@(from),@"to":@(to)}}

//inner type, specified the class in array or the class of dictionary
#define HPInnerType(s) @{@"innertype":s}

//type devide, use on array whose items is of one more type, or use on dictionary whose type if decide by data
//ie. data has a key 'type', if value == 1 , convert itself to Aclass if (value == 2) convert itself to Bclass
//you can write like ppx(@"type", @(1), Aclass, @(2), Bclass)
#define HPDivideType(typekey, type1, class1, ...) @{@"dividetype":@[typekey, type1, class1, __VA_ARGS__]}


@class HDOPropertyExt;

@interface NSObject (HDeserializable)
- (instancetype)h_initWithDictionary:(NSDictionary *)dict error:(NSError **)error;
- (instancetype)h_initWithDictionary:(NSDictionary *)dict enableKeyMap:(BOOL)enableKeyMap couldEmpty:(BOOL)couldEmpty error:(NSError **)error;

//enableKeyMap: enable key mapping feature in deserialize progress?
- (NSError *)h_setWithDictionary:(NSDictionary *)dict enableKeyMap:(BOOL)enableKeyMap couldEmpty:(BOOL)couldEmpty;

//before data examlation and value setting, you can pre-processing data there, if some error occured, please record to self.format_error and return nil
- (id)h_preMapValue:(id)value forKey:(NSString *)key;
//set value to property, you can rewrite it for some special design, if some error occured, please record to self.format_error and return nil
- (NSError *)h_setValue:(id)value forProperty:(HPropertyDetail *)ppDetail exts:(HDOPropertyExt *)propertyExts enableKeyMap:(BOOL)enableKeyMap couldEmpty:(BOOL)couldEmpty;
#pragma mark - advance method

//decide the class in array, according to data, propert info and annotation, if some error occured, please record to self.format_error and return nil
- (Class)h_classInArray:(id)item ppDetail:(HPropertyDetail *)ppDetail error:(NSError **)error;

//decide the class of a dictionaty , according to data, propert info and annotation, if some error occured, please record to self.format_error and return nil
- (Class)h_classForDictionary:(NSDictionary *)item ppDetail:(HPropertyDetail *)ppDetail error:(NSError **)error;

//create obj
- (id)h_createObjectWithClass:(Class)cls;
@end


/**
 *  propert extend attr
 */
@interface HDOPropertyExt : NSObject
@property (nonatomic) BOOL isOptional;
@property (nonatomic) BOOL isIgnore;
@property (nonatomic) BOOL isAutocast;
@property (nonatomic) NSString *keyMapto;
@property (nonatomic) Class innerType;
@property (nonatomic) NSArray *divideType;
@property (nonatomic) NSNumber *from;
@property (nonatomic) NSNumber *to;
- (BOOL)isInRange:(NSNumber *)value;
@end

NS_ASSUME_NONNULL_END
