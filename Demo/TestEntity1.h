//
//  TestEntity.h
//  HAccess
//
//  Created by zhangchutian on 15/9/2.
//  Copyright (c) 2015年 zhangchutian. All rights reserved.
//

#import "HEntity.h"


@protocol TestEntity <NSObject>
@end

@interface TestEntity : HEntity
@property (nonatomic) long x;
@property (nonatomic) float y;
@property (nonatomic) NSNumber *z;
@end


@protocol TestEntity1 <NSObject>
@end
@interface TestEntity1 : HEntity
@property (nonatomic) int a;
@property (nonatomic) NSString *b;
@property (nonatomic) NSArray *ar;
@property (nonatomic) TestEntity *c;
@end


@interface TestEntity2 : HEntity
@property (nonatomic) NSArray<TestEntity> *a;
@property (nonatomic) NSArray *b;
@property (nonatomic) NSDictionary *c;
@end

@interface TestEntity3 : HEntity
@property (nonatomic) int a;
@property (nonatomic) NSNumber *b;
@property (nonatomic) NSString *c;
@property (nonatomic) float d;
@end



@protocol TestEntity4 <NSObject>
@end

@interface TestEntity4 : HEntity
@property (nonatomic) BOOL c;
@property (nonatomic) NSArray *e;
@end

@interface TestEntity5 : HEntity
@property (nonatomic) NSString *a;
@property (nonatomic) NSArray<TestEntity4> *b;
@end


@interface TestEntity6 : HEntity
@property (nonatomic) NSString *a;
@property (nonatomic) int b;
@end



@interface TestEntity7 : HEntity
@property (nonatomic) int a;
@property (nonatomic) NSString *b;
@end


@interface TestEntity8 : HEntity
@property (nonatomic) int a;
@property (nonatomic) NSString *b;
@property (nonatomic) float c;
@end

@protocol TestProtocal <NSObject>

@optional

@property(nonatomic, readonly) id a;
@property(nonatomic, readonly) double b;
@property(nonatomic, readonly) double c;
@property(nonatomic, readonly) NSString *d;

- (NSString *)fun1;

- (long)fun2:(NSString *)userLocation;

@end

@interface TestProtocalIMP : HEntity <TestProtocal>
@property(nonatomic) NSString *d;
@property(nonatomic) NSString *e;
@property(nonatomic) NSString *f;
@end


@interface TestEntity9 : HEntity
@property (nonatomic) int a;
@property (nonatomic) id<TestProtocal> b;
@end


@interface TestEntity10 : HEntity
@property (nonatomic) id pp;
@property (nonatomic) NSArray *arr;
@end
