//
//  HDeserializableObject.h
//  HAccess
//
//  Created by zhangchutian on 16/3/2.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HPropertyMgr.h"
#import <Hodor/NSObject+annotation.h>
#pragma mark - defines

//safe get property name
#define pp_name(k) (self.k?@#k:@#k)


#define HPTest(condition, errorInfo) if (!(condition))\
{\
self.format_error = [NSString stringWithFormat:@"%@:%@", NSStringFromClass(self.class), errorInfo];\
NSAssert(NO,self.format_error);\
return;\
}

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














@interface HDeserializableObject : NSObject <NSCopying>
@property (nonatomic, strong) NSString *format_error;

#pragma mark - basic method


//set data with dictionary
- (void)setWithDictionary:(NSDictionary *)dict;

//enableKeyMap: enable key mapping feature in deserialize progress?
- (void)setWithDictionary:(NSDictionary *)dict enableKeyMap:(BOOL)enableKeyMap;
- (void)setWithDictionary:(NSDictionary *)dict enableKeyMap:(BOOL)enableKeyMap couldEmpty:(BOOL)couldEmpty;
//set with anothor obj, just shallow copy
- (void)setWithDObj:(HDeserializableObject *)obj;

//before data examlation and value setting, you can pre-processing data there, if some error occured, please record to self.format_error and return nil
- (id)preMapValue:(id)value forKey:(NSString *)key;

#pragma mark - advance method

//decide the class in array, according to data, propert info and annotation, if some error occured, please record to self.format_error and return nil
- (Class)classInArray:(id)item ppDetail:(HPropertyDetail *)ppDetail;

//decide the class of a dictionaty , according to data, propert info and annotation, if some error occured, please record to self.format_error and return nil
- (Class)classForDictionary:(NSDictionary *)item ppDetail:(HPropertyDetail *)ppDetail;
@end
