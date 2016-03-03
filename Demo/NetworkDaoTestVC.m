//
//  NetworkDaoTestVC.m
//  HAccess
//
//  Created by zhangchutian on 15/7/3.
//  Copyright (c) 2015年 zhangchutian. All rights reserved.
//

#import "NetworkDaoTestVC.h"
#import <HTextInput/HTextField.h>
#import <HTextInput/HTextInputMotherBoard.h>
#import <HTextInput/HTextAnimationBottom.h>
#import <HTextInput/HTextAnimationPosition.h>
#import <HCommon.h>

@interface NetworkDaoTestVC () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSMutableArray *conversation;
@property (nonatomic) HNetworkDAO *currentDao;
@property (nonatomic) UIView *textBack;
@property (nonatomic) HTextField *textView;
@end

@implementation NetworkDaoTestVC

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
        self.title = @"Say something";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImage *img = [UIImage imageNamed:@"bg.jpg"];
    UIImageView *bg = [[UIImageView alloc] initWithImage:img];
    bg.frame = self.view.bounds;
    ALWAYS_FULL(bg);
    bg.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:bg];

    UIImageView *bg2 = [[UIImageView alloc] init];
    bg2.frame = self.view.bounds;
    ALWAYS_FULL(bg2);
    bg2.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:bg2];

    bg2.alpha = 0;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage *blur = [img blurImage:0.9];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                bg2.image = blur;
                bg2.alpha = 1;
            }];
        });
    });
    self.automaticallyAdjustsScrollViewInsets = NO;
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    _tableView.contentInset = UIEdgeInsetsMake(64, 0, 90, 0);
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:_tableView];
    ALWAYS_FULL(_tableView);

    _conversation = [NSMutableArray new];
    [self.view addSubview:self.textBack];
}
- (UIView *)textBack
{
    if (!_textBack)
    {
        UIView *back = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height - 60, self.view.width, 60)];
        back.backgroundColor = [UIColor colorWithHex:0xf5f5f5];
        back.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        if (!_textView)
        {
            HTextField *textView = [[HTextField alloc] initWithFrame:CGRectMake(10, (back.height - 44)/2, back.width - 20 - 44 - 5, 44)];
            textView.font = [UIFont systemFontOfSize:24];
            textView.layer.cornerRadius = 4;
            textView.backgroundColor = [UIColor whiteColor];
            textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            [back addSubview:textView];
            HTextAnimationBottom *animation1 = [HTextAnimationBottom new];
            animation1.animationView = self.tableView;
            animation1.inputView = textView;
            __weak typeof(back) weakBack = back;
            [animation1 setAdjustDistanceCallback: ^float(float distance){
                return distance + weakBack.height;
            }];
            HTextAnimationPosition *animation2 = [HTextAnimationPosition new];
            animation2.animationView = back;
            animation2.inputView = textView;
            textView.animations = @[animation1, animation2];
            _textView = textView;
        }


        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.layer.cornerRadius = 5;
        btn.backgroundColor = [UIColor colorWithHex:0x0066cc];
        btn.frame = CGRectMake(back.width - 44 - 10, (back.height - 44)/2, 44, 44);
        [btn setTintColor:[UIColor darkGrayColor]];
        [btn setTitle:@"send" forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [back addSubview:btn];
        btn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [btn addTarget:self action:@selector(send) forControlEvents:UIControlEventTouchUpInside];
        _textBack = back;
    }
    return _textBack;
}
- (void)send
{
    UITextField *textView = self.textView;
    NSString *msg = [textView text];
    if (msg.length > 0)
    {
        [self sendMsg:msg textView:textView];
    }
}
- (void)sendMsg:(NSString *)msg textView:(UITextField *)textView
{
    if (_currentDao) return;
    textView.text = @"";
    [self.conversation addObject:msg];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.conversation.count - 1 inSection:0]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];

    DemoNetworkDAO *dao = [DemoNetworkDAO new];
    dao.appkey = @"db5c321697d0fd38ce68988d5a28f97e";
    dao.info = msg;
    _currentDao = dao;
    __weak typeof(self) weakSelf = self;
    [dao startWithQueueName:nil sucess:^(id sender, DemoEntity *data) {
        [weakSelf.conversation addObject:[NSString stringWithFormat:@"lily:%@",data.text]];
        weakSelf.currentDao = nil;
        [weakSelf.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:weakSelf.conversation.count - 1 inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
    } failure:^(id sender, NSError *error) {
        NSLog(@"error:%@", [error localizedDescription]);
        weakSelf.currentDao = nil;
    }];
}

#pragma mark - UITableViewDatasource & UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _conversation.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"CellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.numberOfLines = 0;
        cell.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
    }
    cell.textLabel.text = [_conversation[indexPath.row] stringValue];
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *str = [_conversation[indexPath.row] stringValue];
    CGSize size = [str hSizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(tableView.width - 30, 10000)];
    float height = size.height + 20;
    if (height < 44) height = 44;
    return height;
}
@end



@implementation DemoNetworkDAO

ppx(appkey, HPMapto(@"key"))

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.baseURL = @"http://www.tuling123.com";
        self.pathURL = @"openapi/api";
#ifdef DEBUG
        self.isMock = YES;
#endif
        self.deserializer = [HNEntityDeserializer deserializerWithClass:[DemoEntity class]];
    }
    return self;
}
@end


@implementation DemoEntity
ppx(otherInfo, HPIgnore)
@end