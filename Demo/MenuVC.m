//
//  MenuVC.m
//  HAccess
//
//  Created by zhangchutian on 15/7/3.
//  Copyright (c) 2015年 zhangchutian. All rights reserved.
//

#import "MenuVC.h"
#import "User.h"
#import "Student.h"
#import "UserLocalDao.h"
#import "NetworkDaoTestVC.h"
#import "DeserializeDemo.h"
#import "HFileCache.h"
#import "TestEntity1.h"
#import "HCommon.h"
//#import <ProtocolBuffers/ProtocolBuffers.h>
#import "HEntity+Persistence.h"

@implementation MenuVC
- (instancetype)init
{
    self = [super init];
    if (self) {
        __weak typeof(self) weakSelf = self;
        
        [self addMenu:@"network test" callback:^(id sender, id data) {
            [weakSelf testNetwork];
        }];

        [self addMenu:@"deserialize test" callback:^(id sender, id data) {
            [weakSelf testEntity];
        }];

        [self addMenu:@"DB DAO Test" subTitle:@"see the demo code" callback:^(id sender, id data) {
            [weakSelf testDBDAO];
        }];
        
        [self addMenu:@"DB Entity Test" subTitle:@"see the demo code" callback:^(id sender, id data) {
            [weakSelf testDBEntity];
        }];
        
        [self addMenu:@"Another DB Test" subTitle:@"see the demo code" callback:^(id sender, id data) {
            [weakSelf testDBEntity2];
        }];
    }
    return self;
}
- (void)testNetwork
{
    [self.navigationController pushViewController:[NetworkDaoTestVC new] animated:YES];
}

- (void)testEntity
{
    [self.navigationController pushViewController:[DeserializeDemo new] animated:YES];
}
- (User *)newUser
{
    User *newUser = [User new];
    newUser.name = @"lisa's";
    newUser.sex = arc4random()%2;
    newUser.birth = (long)14554223423;
    newUser.desc = [NSString stringWithFormat:@"Im desc %d", arc4random()%100];
    return newUser;
}
- (Student *)newStudent
{
    Student *newUser = [Student new];
    newUser.name = @"lisa";
    newUser.level = arc4random()%6 + 1;
    return newUser;
}
- (void)testDBDAO
{
    NSLog(@"create data access");
    UserLocalDao *userDao = [[UserLocalDao alloc] init];
    NSLog(@"batch delete");
    [userDao removes:nil];
    NSLog(@"create new data model");
    User *newUser = [self newUser];
    NSLog(@"I have create a user: \n%@",[newUser jsonString]);
    [userDao add:newUser];
    NSString *ID = [userDao lastInsertedID];
    NSLog(@"last inserted ID is %@",ID);
    
    BOOL bSuc = [User addIndex:@"birth"];
    NSLog(@"create User table(birth) index %@", bSuc ? @"successfully" : @"failed");
    
    NSLog(@"query User by ID:%@",ID);
    User *auser = (User *)[userDao get:ID];
    NSLog(@"User from db:\n%@",[auser jsonString]);
    NSLog(@"update the user，change desc to ‘new desc’");
    auser.desc = @"new desc";
    [userDao update:auser];
    NSLog(@"query the User after update");
    User *updatedUser = (User *)[userDao get:ID];
    NSLog(@"%@",[updatedUser jsonString]);
    NSLog(@"the 'desc' and 'modified' of the old object has been changed\n%@",[auser jsonString]);
    NSLog(@"insert 10 item");
    for (int i = 0; i < 10; i ++)
    {
        [userDao add:[self newUser]];
    }
    NSLog(@"query all user");
    NSArray *users = [userDao list:nil];
    for (User *auser in users)
    {
        NSLog(@"%@", [auser jsonString]);
    }
    NSLog(@"condition query: sex=0");
    users = [userDao list:@"sex = 0"];
    for (User *auser in users)
    {
        NSLog(@"%@", [auser jsonString]);
    }
    NSLog(@"query count");
    long count = [userDao count:@"sex = 0"];
    NSLog(@"there are %li User which sex=0",count);
    NSLog(@"total count %li",[userDao count:nil]);
    NSLog(@"insert 10 more");
    NSMutableArray *batchUsers = [[NSMutableArray alloc] init];
    for (int i = 0; i < 10; i ++)
    {
        [batchUsers addObject:[self newUser]];
    }
    [userDao adds:batchUsers];
    NSLog(@"total count %li",[userDao count:nil]);
    NSLog(@"update user's name to peter which sex=0");
    [userDao updatesWithSetters:@{@"name":@"DG.t's peter"} conditions:@"sex = 0"];
    NSLog(@"query user which sex = 0");
    users = [userDao list:@"sex = 0"];
    for (User *user in users)
    {
        NSLog(@"%@",[user jsonString]);
    }
}



- (void)testDBEntity
{
    NSLog(@"batch delete");
    [User removes:nil];
    NSLog(@"create new data model");
    User *newUser = [self newUser];
    NSLog(@"I have create a user: \n%@",[newUser jsonString]);
    [newUser save];
    NSString *ID = [User lastInsertedID];
    NSLog(@"last inserted ID is %@",ID);
    
    NSLog(@"query User by ID:%@",ID);
    User *auser = (User *)[User get:ID];
    NSLog(@"User from db:\n%@",[auser jsonString]);
    NSLog(@"update the user，change desc to ‘new desc’");
    auser.desc = @"new desc";
    [auser update];
    NSLog(@"query the User after update");
    User *updatedUser = (User *)[User get:ID];
    NSLog(@"%@",[updatedUser jsonString]);
    NSLog(@"the 'desc' and 'modified' of the old object has been changed\n%@",[auser jsonString]);
    NSLog(@"insert 10 item");
    for (int i = 0; i < 10; i ++)
    {
        [[self newUser] add];
    }
    NSLog(@"query all user");
    NSArray *users = [User list:nil];
    for (User *auser in users)
    {
        NSLog(@"%@", [auser jsonString]);
    }
    NSLog(@"condition query: sex=0");
    users = [User list:@"sex = 0"];
    for (User *auser in users)
    {
        NSLog(@"%@", [auser jsonString]);
    }
    NSLog(@"query count");
    long count = [User count:@"sex = 0"];
    NSLog(@"there are %li User which sex=0",count);
    NSLog(@"total count %li",[User count:nil]);
    NSLog(@"insert 10 more");
    NSMutableArray *batchUsers = [[NSMutableArray alloc] init];
    for (int i = 0; i < 10; i ++)
    {
        [batchUsers addObject:[self newUser]];
    }
    [User adds:batchUsers];
    NSLog(@"total count %li",[User count:nil]);
    NSLog(@"update user's name to peter which sex=0");
    [User updatesWithSetters:@{@"name":@"peter"} conditions:@"sex = 0"];
    NSLog(@"query user which sex = 0");
    users = [User list:@"sex = 0"];
    for (User *user in users)
    {
        NSLog(@"%@",[user jsonString]);
    }
}

- (void)testDBEntity2
{
    NSLog(@"batch delete");
    [Student removes:nil];
    NSLog(@"create new Student model");
    Student *newStudent = [self newStudent];
    NSLog(@"I have create a Student: \n%@",[newStudent jsonString]);
    [newStudent save];
    NSString *ID = [Student lastInsertedID];
    NSLog(@"last inserted ID is %@",ID);
    
    NSLog(@"query Student by ID:%@",ID);
    Student *aStudent = (Student *)[Student get:ID];
    NSLog(@"Student from db:\n%@",[aStudent jsonString]);
    
    NSLog(@"total Student count : %li", [Student count:nil]);
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
