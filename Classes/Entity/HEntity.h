//
//  HEntity.h
//  HAccess
//
//  Created by zhangchutian on 14-9-19.
//  Copyright (c) 2014年 zhangchutian. All rights reserved.
//

//  如果你不希望某个属性被存储，那么请以“tmp_”开头
#import <Foundation/Foundation.h>
#import "HDeserializableObject.h"


/**
 *  This is the base class of data entity
 *  it provides a very simple deserialize solution, and it is safe, and flexable
 *  the solution is based on key mapping, (property ~ dirctionary key), and in the mapping progress, it make a strict examlation by default, and it provides some exceptional case for special requirement
 *
 *  @convention: if the entity map to database table, please let the entity name same to the tablename, 
 *  then you can be more efficient. [HDBMgrDatasource entityClassNameForTable:] just return table name
 */
@interface HEntity : HDeserializableObject
@property (nonatomic, strong) NSString *ID;
@property (nonatomic, assign) long created;
@property (nonatomic, assign) long modified;


//set with anothor entity, just shallow copy
- (void)setWithEntity:(HEntity *)entity;

//database primary key, default is id
- (NSString *)keyProperty;

//key value operation wapping , ie. if you has some property , it need encript before input to db and need decript after output from db, you can rewrite this mehtod.
- (void)hSetValue:(id)value forKey:(NSString *)key;
- (id)hValueForKey:(NSString *)key;

@end



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
