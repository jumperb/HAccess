//
//  DeserializeDemo.m
//  HAccess
//
//  Created by zhangchutian on 15/9/19.
//  Copyright (c) 2015年 zhangchutian. All rights reserved.
//

#import "DeserializeDemo.h"
#import "TestEntity1.h"
#import <HCommon.h>
@implementation DeserializeDemo
- (instancetype)init
{
    self = [super init];
    self.title = @"Deserialize Demo";
    if (self) {
        [self addMenu:@"recursion" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"a":@(1),@"b":@"2##",
                                   @"c":@{
                                           @"x":@(3),
                                           @"y":@(4.2),
                                           @"z":@(5.5)
                                           }
                                   };
            TestEntity1 *entity = [TestEntity1 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];

        [self addMenu:@"deserialize array" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"a":@[
                                        @{@"x":@(3),@"y":@(4.2),@"z":@(5.5)},
                                        @{@"x":@(3),@"y":@(4.2),@"z":@(5.5)},
                                        @{@"x":@(3),@"y":@(4.2),@"z":@(5.5)}
                                       ],
                                   @"b":@[@{@"x":@(3),@"y":@(4.2),@"z":@(5.5)},
                                           @{@"x":@(3),@"y":@(4.2),@"z":@(5.5)}],
                                   @"c":@{@"x":@(3),@"y":@(4.2),@"z":@(5.5)}};
            TestEntity2 *entity = [TestEntity2 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];
        [self addMenu:@"deserialize array 2，innertype tag" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"c":@(1),
                                   @"e":@[
                                           @{@"a":@(1),@"b":@"2##",
                                             @"c":@{
                                                     @"x":@(3),
                                                     @"y":@(4.2),
                                                     @"z":@(5.5)
                                                     }
                                             },
                                           @{@"a":@(1),@"b":@"2##",
                                             @"c":@{
                                                     @"x":@(3),
                                                     @"y":@(4.2),
                                                     @"z":@(5.5)
                                                     }
                                             }
                                           ]};
            TestEntity4 *entity = [TestEntity4 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];
        [self addMenu:@"check empty, nil" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"a":@(1),@"b":@(2),@"c":@"c"};
            TestEntity3 *entity = [TestEntity3 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];

        [self addMenu:@"check empty, nil 2" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"a":@(1),@"b":@(2),@"c":[NSNull null], @"d":@(4)};
            TestEntity3 *entity = [TestEntity3 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];

        [self addMenu:@"HPOptional tag" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"a":@(1),@"c":@"c", @"d":@(4)};
            TestEntity3 *entity = [TestEntity3 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];

        [self addMenu:@"check type" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"a":@(1),@"b":@"2",@"c":@"c", @"d":@(4)};
            TestEntity3 *entity = [TestEntity3 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];

        [self addMenu:@"check type 2" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"a":@(1),@"c":@(1), @"d":@(4)};
            TestEntity3 *entity = [TestEntity3 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];

        [self addMenu:@"check type 3" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"a":@(1),@"b":@"2",@"c":@[], @"ar":@[]};
            TestEntity1 *entity = [TestEntity1 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];

        [self addMenu:@"check type 4" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"a":@(1),@"b":@"2",@"c":([TestEntity new]), @"ar":@[]};
            TestEntity1 *entity = [TestEntity1 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];
        [self addMenu:@"check value scope 1" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"a":@(11),@"b":@"12",@"c":@{
                                           @"x":@(3),
                                           @"y":@(4.2),
                                           @"z":@(5.5)
                                           }, @"ar":@[]};
            TestEntity1 *entity = [TestEntity1 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];
        [self addMenu:@"check value scope 2" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"a":@"12",@"b":@"12",@"c":@{
                                           @"x":@(3),
                                           @"y":@(4.2),
                                           @"z":@(5.5)
                                           }, @"ar":@[]};
            TestEntity1 *entity = [TestEntity1 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];

        [self addMenu:@"a complex deserializing" callback:^(id sender, id data) {

            NSDictionary *dict = @{@"a":@"a",@"b":@[
                                                @{@"c":@(1),
                                                  @"d":@{@"x":@(3),@"y":@(4.2),@"z":@(5.5)},
                                                  @"e":@[
                                                          @{@"a":@(1),@"b":@"1##",@"c":@{@"x":@(3),@"y":@(4.2),@"z":@(5.5)}},
                                                          @{@"a":@(1),@"b":@"2##",@"c":@{@"x":@(3),@"y":@(4.2),@"z":@(5.5)}},
                                                          @{@"a":@(1),@"b":@"3##",@"c":@{@"x":@(3),@"y":@(4.2),@"z":@(5.5)}}
                                                          ]}
                                           ]};

            TestEntity5 *entity = [TestEntity5 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];

        [self addMenu:@"property annotation" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"cc":@(2)};
            TestEntity6 *entity = [TestEntity6 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];

        [self addMenu:@"autocast test" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"a":@"1",@"b":@(2)};
            TestEntity7 *entity = [TestEntity7 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];

        [self addMenu:@"autocast test2" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"a":@"1",@"b":@(2),@"c":@"c", @"d":@(1464142086)};
            TestEntity8 *entity = [TestEntity8 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@ date = %@", [entity h_jsonString], [entity.d displayDesc]);
        }];
        
        [self addMenu:@"entity with protocal test" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"d":@"1",@"e":@(2),@"f":@"f"};
            TestProtocalIMP *entity = [TestProtocalIMP new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];
        
        [self addMenu:@"entity contain id<xxx> test" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"a":@(1),
                                   @"b":@{@"d":@"1",@"e":@(2),@"f":@"f"}};
            TestEntity9 *entity = [TestEntity9 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];
        
        [self addMenu:@"HPDivideType test" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"pp":@{@"type":@"4",@"d":@"1",@"e":@(2),@"f":@"f"},
                                   @"arr":@[
                                           @{@"type":@(4),@"d":@"1",@"e":@(2),@"f":@"f"},
                                           @{@"type":@"TestEntity",@"x":@(3),@"y":@(4.2),@"z":@(5.5)},
                                           @{@"type":@(5),@"d":@"1",@"e":@(2),@"f":@"f"}
                                           ]};
            TestEntity10 *entity = [TestEntity10 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];

        [self addMenu:@"Reserved works test" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"created":@(1231241),@"modified":@(443434)};
            TestEntity11 *entity = [TestEntity11 new];
            [entity setWithDictionary:dict];
            if (entity.format_error)
            {
                NSLog(@"%@",entity.format_error);
            }
            else NSLog(@"deserialize success:%@", [entity h_jsonString]);
        }];

        [self addMenu:@"NSCopying" callback:^(id sender, id data) {
            NSDictionary *dict = @{@"a":@"a",@"b":@[
                                           @{@"c":@(1),
                                             @"d":@{@"x":@(3),@"y":@(4.2),@"z":@(5.5)},
                                             @"e":@[
                                                     @{@"a":@(1),@"b":@"1##",@"c":@{@"x":@(3),@"y":@(4.2),@"z":@(5.5)}},
                                                     @{@"a":@(1),@"b":@"2##",@"c":@{@"x":@(3),@"y":@(4.2),@"z":@(5.5)}},
                                                     @{@"a":@(1),@"b":@"3##",@"c":@{@"x":@(3),@"y":@(4.2),@"z":@(5.5)}}
                                                     ]}
                                           ]};

            TestEntity5 *entity = [TestEntity5 new];
            [entity setWithDictionary:dict];

            TestEntity5 *copy = [entity copy];
            NSLog(@"%@", [copy h_jsonString]);
        }];
    }
    return self;
}
- (void)viewDidLoad
{
    UIImageView *bg = [[UIImageView alloc] initWithImage:img(@"bg.jpg")];
    bg.frame = self.view.bounds;
    ALWAYS_FULL(bg);
    bg.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:bg];
    [super viewDidLoad];
    self.tableView.backgroundColor = [UIColor clearColor];

}
@end
