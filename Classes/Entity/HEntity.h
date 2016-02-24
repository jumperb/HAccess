//
//  HEntity.h
//  HAccess
//
//  Created by zhangchutian on 14-9-19.
//  Copyright (c) 2014年 zhangchutian. All rights reserved.
//

//  如果你不希望某个属性被存储，那么请以“tmp_”开头
#import <Foundation/Foundation.h>
#import "HEntityMgr.h"
#import <NSObject+annotation.h>





/**
 *  This is the base class of data entity
 *  it provides a very simple deserialize solution, and it is safe, and flexable
 *  the solution is based on key mapping, (property ~ dirctionary key), and in the mapping progress, it make a strict examlation by default, and it provides some exceptional case for special requirement
 *
 *  @convention: if the entity map to database table, please let the entity name same to the tablename, 
 *  then you can be more efficient. [HDBMgrDatasource entityClassNameForTable:] just return table name
 */
@interface HEntity : NSObject
@property (nonatomic, strong) NSString *ID;
@property (nonatomic, assign) long created;
@property (nonatomic, assign) long modified;
@property (nonatomic, strong) NSString *format_error;

#pragma mark - basic method


//set data with dictionary
- (void)setWithDictionary:(NSDictionary *)dict;

//enableKeyMap: enable key mapping feature in deserialize progress?
- (void)setWithDictionary:(NSDictionary *)dict enableKeyMap:(BOOL)enableKeyMap;

//before data examlation and value setting, you can pre-processing data there, if some error occured, please record to self.format_error and return nil
- (id)preMapValue:(id)value forKey:(NSString *)key;

//set with anothor entity, just shallow copy
- (void)setWithEntity:(HEntity *)entity;

#pragma mark - advance method

//decide the class in array, according to data, propert info and annotation, if some error occured, please record to self.format_error and return nil
- (Class)classInArray:(id)item ppDetail:(HEntityPropertyDetail *)ppDetail;

//decide the class of a dictionaty , according to data, propert info and annotation, if some error occured, please record to self.format_error and return nil
- (Class)classForDictionary:(NSDictionary *)item ppDetail:(HEntityPropertyDetail *)ppDetail;

//database primary key, default is id
- (NSString *)keyProperty;

//key value operation wapping , ie. if you has some property , it need encript before input to db and need decript after output from db, you can rewrite this mehtod.
- (void)hSetValue:(id)value forKey:(NSString *)key;
- (id)hValueForKey:(NSString *)key;

@end

#pragma mark - defines

//safe get property name
#define pp_name(k) (self.k?@#k:@#k)

//assertion
#define HPTest(condition, errorInfo) if (!(condition))\
{\
self.format_error = [NSString stringWithFormat:@"%@:%@", NSStringFromClass(self.class), errorInfo];\
NSAssert(NO,self.format_error);\
return;\
}

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



#pragma mark - deserializer protocal

/**
 *  deserializer protocal
 */
@protocol HEDeserializer <NSObject>
/**
 *  do deserialize
 *
 *  @param rudeData
 *
 *  @return entity
 */
- (id)deserialization:(id)rudeData;
@end
