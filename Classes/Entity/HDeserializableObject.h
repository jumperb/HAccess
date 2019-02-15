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
#import "NSObject+HDeserializable.h"
#pragma mark - defines














@class HDOPropertyExt;

@interface HDeserializableObject : NSObject <NSCopying>
@property (nonatomic, strong) NSString *format_error;

#pragma mark - basic method
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict enableKeyMap:(BOOL)enableKeyMap couldEmpty:(BOOL)couldEmpty;

//set data with dictionary
- (void)setWithDictionary:(NSDictionary *)dict;

//enableKeyMap: enable key mapping feature in deserialize progress?
- (void)setWithDictionary:(NSDictionary *)dict enableKeyMap:(BOOL)enableKeyMap;
- (void)setWithDictionary:(NSDictionary *)dict enableKeyMap:(BOOL)enableKeyMap couldEmpty:(BOOL)couldEmpty;
//set with anothor obj, just shallow copy
- (void)setWithDObj:(HDeserializableObject *)obj;

//before data examlation and value setting, you can pre-processing data there, if some error occured, please record to self.format_error and return nil
- (id)preMapValue:(id)value forKey:(NSString *)key;
//set value to property, you can rewrite it for some special design, if some error occured, please record to self.format_error and return nil
- (void)setValue:(id)value forProperty:(HPropertyDetail *)ppDetail exts:(HDOPropertyExt *)propertyExts enableKeyMap:(BOOL)enableKeyMap couldEmpty:(BOOL)couldEmpty;
#pragma mark - advance method

//decide the class in array, according to data, propert info and annotation, if some error occured, please record to self.format_error and return nil
- (Class)classInArray:(id)item ppDetail:(HPropertyDetail *)ppDetail;

//decide the class of a dictionaty , according to data, propert info and annotation, if some error occured, please record to self.format_error and return nil
- (Class)classForDictionary:(NSDictionary *)item ppDetail:(HPropertyDetail *)ppDetail;

//create obj
- (id)createObjectWithClass:(Class)cls;
@end



