# What？
HAccess是介于一个网络数据,数据库数据与业务层之间的一个库，主要目的是降低业务层对这些数据的访问成本。
在大多数情况下，可以直接不需要业务层，直接通过controller层即可快速访问数据了。
库主要由HDeserializableObject，HNetworkDAO和HDatabaseDAO构成
### HNetworkDAO 特性如下
* 面向对象的接口管理方式
* 请求参数映射
* 极简的反序列化支持
* 具有模型验证能力
* 请求生命周期可扩展
* 极简的队列控制
* 极简的缓存控制
* 极简的mock功能

### HDatabaseDAO 特性如下
TODO


# How？


## 一.文件下载
``` objectivec
HNetworkDAO *dao = [HNetworkDAO new];
dao.baseURL = @"https://uploadbeta.com/api/pictures/random/?key=%E6%8E%A8%E5%A5%B3%E9%83%8E";
dao.isFileDownload = YES; //注释1
[dao start:^(id sender, id data) {
    NSLog(@"数据是%@", [data jsonString]);//注释2
} failure:^(id sender, NSError *error) {
    NSLog(@"error:%@", error.localizedDescription);
}]; 
```

//注释1 由于这里是文件下载，所以必须指明是文件下载，目前还没支持根据响应的content-type来决定返回啥东西，主要是AFNetworking还没支持  
//注释2 jsonString在  #import <NSObject+ext.h> 这个里面

如果有报错
```
错误:Error Domain=Network Code=-1022 "The resource could not be loaded because the App Transport Security policy requires the use of a secure connection." UserInfo={NSLocalizedDescription=The resource could not be loaded because the App Transport Security policy requires the use of a secure connection.}
```
在info.plist里面添加
```
<key>NSAppTransportSecurity</key>
<dict>
     <key>NSAllowsArbitraryLoads</key>
     <true/>
</dict>
```
下载好了，获取到返回
```
{
  "length" : 49181,
  "suggestedFilename" : "random.jpeg",
  "MIMEType" : "image\/jpeg",
  "filePath" : "\/Users\/zct\/Library\/Developer\/CoreSimulator\/Devices\/19BED3C5-5BBF-49E7-A82B-8BC7ED436B1C\/data\/Containers\/Data\/Application\/AF88FB0F-E5CE-40B6-BFCE-9C685EAE7CFF\/Library\/Caches\/com.hacess.HFileCache\/1570A0716FA3979787A9EA27BB253518"
}
```

这是一个内置的数据结构
```objectivec
/**
 *  file download info
 *  if HNetworkDAO.isFileDownload is YES, you will recv a response of this type if successed
 *  once you have downloaded, move the file to other place, otherwise it will be deleted after 1 minute
 */
@interface HDownloadFileInfo : NSObject
@property (nonatomic) NSString *filePath;
@property (nonatomic) NSString *MIMEType;
@property (nonatomic) long long length;
@property (nonatomic) NSString *suggestedFilename;
@end
```
直接拿着用就好了，
**注意：**如果需要存储的话一定要移走，因为放在原地的话，1小时候会被删除
关于com.hacess.HFileCache这个，我们在后面的文章讲

可以看出这是一个图片下载，接着我们把这段代码复制一份做成一个函数，以便后面的demo使用
``` objectivec
- (void)showImageURL:(NSString *)url
{
    HNetworkDAO *dao = [HNetworkDAO new];
    dao.baseURL = url;
    dao.isFileDownload = YES;
    [dao start:^(id sender, HDownloadFileInfo *data) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.image = [UIImage imageWithContentsOfFile:data.filePath];
        [self.view addSubview:imageView];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [imageView removeFromSuperview];
        });
    } failure:^(id sender, NSError *error) {
        NSLog(@"error:%@", error.localizedDescription);
    }];
}
```


## 二.简单接口调用

接口api https://uploadbeta.com/picture-gallery/faq.php#api 的search接口  
首先，HAccess建议使用面向对象的代码组织方式，所有的请求类，模型类都是在一个继承关系中的

创建SimpleDAO作为HNetworkDAO的子类
```objectivec
#import <HAccess/HNetworkDAO.h>
@interface SimpleDAO : HNetworkDAO
@property (nonatomic) NSString *searchKey;
@end
```
```objectivec
@implementation SimpleDAO
ppx(searchKey, HPMapto(@"key"))
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.baseURL = @"https://uploadbeta.com";
        self.pathURL = @"/api/pictures/search/?start=1&offset=10";
    }
    return self;
}
@end
```
测试一下
```objectivec
[self addMenu:@"简单请求" callback:^(id sender, id data) {
    SimpleDAO *dao = [SimpleDAO new];
    dao.searchKey = @"sexy";
    [dao start:^(id sender, id data, NSError *error) {
        NSLog(@"data:%@",data);
    }];
}];
```

不出意外，你会获得一个字典返回

**注意:** “.m”文件里面有个ppx描述，这种写法叫做“属性注解”，这是一个属性描述方法，这句话的意思是说，把ID映射到id，为啥要映射啊？
A.服务器参数有objective-c的保留字
B.服务端参数名太随意，而我们有洁癖
C.如果服务端要日怪，非要把参数放在 http header 里面，还可以这样
```objectivec
ppx(searchKey, HPMapto(@"key"), HPHeader)
```

## 三.简单反序列化

SimpleDAO下发下来应该是个图集对象，我们希望直接能获取到一个直接可用的业务模型
我们先根据返回数据编写模型,可以直接写在SimpleDAO里面，我们期望返回的模型如下定义
```objectivec
@interface ImageObject : HDeserializableObject
@property (nonatomic) NSString *ID;
@property (nonatomic) NSString *url;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *fullImageURL;
@end
```
```objectivec
@implementation ImageObject
- (NSString *)fullImageURL
{
    if (!_fullImageURL)
    {
        _fullImageURL = [@"https://uploadbeta.com/_s/" stringByAppendingString:self.url];
    }
    return _fullImageURL;
}
@end

```
为了顺利进行反序列化，我们让他都继承自HDeserializableObject
并且在SimpleDAO的init函数中添加如下语句，告知DAO需要反序列化成什么
```objectivec
self.deserializer = [HNArrayDeserializer deserializerWithClass:[ImageObject class]];
```
HNArrayDeserializer 是指一种反序列化为数组的反序列化器，反序列化器内置只有有三种：

HNEntityDeserializer(反序列化为对象，支持对象的嵌套)，
HNArrayDeserializer(反序列化为数组)，
HNManualDeserializer（人工反序列化） 就能满足所有的情况。

再试一试？

你会依次遇到几个问题，后面是解决方式

`1.ImageObject的属性叫ID 但是数据的key叫id`  

将头文件的id改成大写然后做属性映射
ppx(ID, HPMapto(@"id”))

`2.服务端下发的id是数字，但是我们要求是字符串，怎么办？`  
ppx(ID, HPMapto(@"id"), HPAutoCast) //AutoCast是指字符串和数字可以按需自动转换

`3.框架报了ImageObject的fullImageURL不能为空，那个只是客户端使用的，不需要转化的`  
ppx(fullImageURL, HPIgnore) //忽略掉

整体代码如下
```objectivec
@implementation ImageObject
ppx(ID, HPMapto(@"id"), HPAutoCast)
ppx(fullImageURL, HPIgnore)
- (NSString *)fullImageURL
{
    if (!_fullImageURL)
    {
        _fullImageURL = [@"https://uploadbeta.com/_s/" stringByAppendingString:self.url];
    }
    return _fullImageURL;
}
@end
```


## 四.服务端错误处理

错误分为三种级别：

* 1.从NSURLSession来的错误，从AFNetworking来的错误，这种错误的Domain是“Network”
例如，http的404，500等

* 2.服务端返回业务错误码，这种错误的Domain是“Server”，例如
{"code":"100002","info":"系统忙，请稍候再试"}

* 3.服务端的数据不合格，被客户端检查出来了，这种错误的Domain是识别到错误的模块，code是“kDataFormatErrorCode”，例如json解码失败，数据字段缺失等，例如"com.haccess.HNJsonDeserializer.HNEntityDeserializer,ImageObject:ID must be @NSString type"

其中第一种和第三种都是自动处理了，第二种需要代码来检测，框架不知道哪个代表成功哪个代表错误
例如如下的返回结果
```objectivec
{"msg":"访问权限错误","status":false}
```
我们会在json解析完成后来检查数据是不是代表错误，检查代码写在哪儿呢？
首先HNetworkDAO有个生命周期，类似UIViewController，这些都是一些请求过程的关键环节，可以在子类中自定义
```objectivec
#pragma mark - life circle
//设置请求头部
- (void)setupHeader:(NSMutableDictionary *)headers;
//设置参数
- (id)setupParams;
//设置参数字典
- (void)setupParams:(NSMutableDictionary *)params;
//设置参数完成
- (void)didSetupParams:(NSMutableDictionary *)params;
//将要发送请求，带上下文参数的
- (void)willSendRequest:(NSString *)urlString method:(NSString *)method headers:(NSMutableDictionary *)headers params:(NSMutableDictionary *)params;
//将要发送请求
- (void)willSendRequest:(NSMutableURLRequest *)request;
//开始请求
- (void)startWithQueueName:(NSString*)queueName;
//获得响应
- (void)requestFinishedSucessWithInfo:(NSData *)responInfo response:(NSURLResponse *)response;
//获取响应对象
- (id)getOutputEntiy:(id)responseObject;
//获取到错误
- (void)requestFinishedFailureWithError:(NSError*)error;
```

我们需要做的服务器错误处理就发生在"getOutputEntiy"这个环节
复写这个方法
```objectivec
- (id)getOutputEntiy:(id)responseObject
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) return herr(kDataFormatErrorCode, @"预期响应格式是一个字典");
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    if (responseDict[@"status"] && [responseDict[@"status"] boolValue] && !responseDict[@"msg"])
    {
        return [super getOutputEntiy:responseObject];
    }
    else
    {
        NSString *msg = responseDict[@"msg"];
        if (!msg) msg = @"服务端错误";
        return herr(503, msg);
    }
}
```
这样我们就可以把错误报到上层去了
Error Domain=SimpleDAO.m Code=503 "访问权限错误！" UserInfo={NSLocalizedDescription=访问权限错误！

## 五.生命周期的作用

我们来做个简单的签名
签名算法:所有请求参数，把key按照升序排列，数据按照a=1&b=2的方式连接成串，追加"123456"进行MD5得到sign，然后再通过sign传到服务器
```objectivec
- (NSString *)sign:(NSDictionary *)params
{
    NSArray *keys = [params keysSortedByValueUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    NSMutableString *signString = [NSMutableString new];
    for (NSString *key in keys)
    {
        if (signString.length == 0)
        {
            [signString appendFormat:@"%@=%@", key, params[key]];
        }
        else
        {
            [signString appendFormat:@"&%@=%@", key, params[key]];
        }
    }
    [signString appendString:@"123456"];
    return [signString md5];
}
```
那么在哪儿写入呢？
```objectivec
- (void)willSendRequest:(NSString *)urlString method:(NSString *)method headers:(NSMutableDictionary *)headers params:(NSMutableDictionary *)params
{
    [super willSendRequest:urlString method:method headers:headers params:params];
    params[@"sign"] = [self sign:params];
}
```
好了，发个请求试试吧

## 7.复杂反序列化

#### 7.1 反序列化路径
如果数据层次较复杂，SimpleDAO是不知道你关心那一部分数据的，这里就需要指定反序列化路径了，例如
```
{
	"resp":{
		"data":{
			//我关心的数据
		}
	}
	"code":123,
	"msg":"成功"
}
```
反序列化路径就这样写
```objectivec
self.deserializeKeyPath = @"resp.data";
```


#### 7.2 反序列化选项

我们之前已经接触到了几个反序列化选项
`HPMapto`: 属性映射关系
`HPIgnore`: 忽略这个属性，不要对这个属性进行反序列化
`HPAutoCast`: 字符串和数字自动按需转换

然而还有四个选项没告诉大家

`HPOptional`:  这个属性可以为空
`HPInnerType`: 指明内部类型，常用于指明数组内部是啥类型
`HPScope`: 这个属性的值域是什么，一般用于描述枚举类型
`HPDivideType`: 类型分离，用于决定数组内部类型或者字典对应类型，例如数组中的数据
```json
[
    {
        "type":"pic",
        "picUrl":"http://www.abc.jpg",
        "picW":450,
        "picH":450
    },
    {
        "type":"video",
        "videoUrl":"http://www.drf.mp4",
        "videoW":450,
        "videoH":450
    }
]
```
需要将 type == pic 的字典转换成 PicObject, type == video 则转换成 VideoObject
那么就可以这样写
```
ppx(某个属性, HPDivideType(@"type", "pic", [PicObject class], "video", [VideoObject class]))
```
除了字符串 ，这里还可以填写 @(1), @(枚举值) 作为type的值

记住这七个选项的作用，需要用到的时候再来查看Demo中的用法
注意: 反序列化选项`对DAO的属性同样适用`，例如，你定义的属性名和请求参数的名字可以不一样！并通过HPMapto转换过去


## 七.队列控制

在上文中我们已经能获取到一个图片数组了，我们现在想要把图片显示出来
请求那儿改成这样
```objectivec
SimpleDAO *dao = [SimpleDAO new];
dao.searchKey = @"sexy";
[dao start:^(id sender, NSArray *data, NSError *error) {
    @strongify(self)
    if (error)
    {
        NSLog(@"%@",error);
    }
    else
    {
        for (ImageObject *imgObj in data)
        {
            [self showImageURL:[imgObj fullImageURL]];
        }
    }
}];
```
这时我们发现图片有时候会同时回来，前一张会把后一张盖住，原因是下载图片的请求我们是同时发出去的。
我们可以让请求排队执行，以解决这个问题

#### 7.1并发控制

我们修改一下showImageURL这个函数
```objectivec
- (void)showImageURL:(NSString *)url
{
    HNetworkDAO *dao = [HNetworkDAO new];
    dao.baseURL = url;
    dao.isFileDownload = YES;
    [dao startWithQueueName:@"imageDownloadQueue" sucess:^(id sender, HDownloadFileInfo *data) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.image = [UIImage imageWithContentsOfFile:data.filePath];
        [self.view addSubview:imageView];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [imageView removeFromSuperview];
        });
    } failure:^(id sender, NSError *error) {
        NSLog(@"error:%@", error.localizedDescription);
    }];
}
```
观察图片回来的log，就可以发现他是一张一张回来的了, 原因是我们给他指明了一个队列imageDownloadQueue，默认情况下这个是个串行的
如果希望设置并发数量，可以在请求开始之前设置
```objectivec
[HNetworkDAO initQueueWithName:@"imageDownloadQueue" maxMaxConcurrent:2];
```
#### 7.2队列回调

我们希望在所有图片下载完成后得到一个通知
```objectivec
@strongify(self)
[HNetworkDAO initQueueWithName:@"imageDownloadQueue" maxMaxConcurrent:2];

for (ImageObject *imgObj in data)
{
    [self showImageURL:[imgObj imageURL]];
}

[HNetworkDAO queue:@"imageDownloadQueue" finish:^(id sender) {
    NSLog(@"所有图片下载完成");
}];
```
## 八.缓存控制

某个页面有个请求，需要间隔8小时才能发送请求，没到8小时，则展示缓存数据
在SimpleDAO的初始化方法中添加如下一行
```objectivec
self.cacheType = [HNCacheTypeAlternative createWtihNextRequstInterval:60*60*8];
```
还有其他缓存类型可选`HNCacheTypeBoth`，`HNCacheTypeOnlyWrite`，也可以自定义，需要用到再去研究吧。
缓存存放位置 = `[HFileCache shareCache].cacheDir`

再试一下，发现缓存起作用了。
但是我们发现输入ID不同，没有导致缓存失效，但是，按照这个接口的意义，不同的ID应该对应不同的缓存对象！怎么办呢？
那么我们需要给缓存key添加ID，在SimpleDAO.m中添加如下函数
```objectivec
- (NSString *)cacheKey
{
    return [[super cacheKey] stringByAppendingString:self.searchKey];
}
```
再试试写死ID，或者更改ID的情况


## 九.请求模拟-Mock

###9.1 自动Mock
自动mock的基础是猜测法，意思是说，框架来猜你要啥样的数据

##### 9.1.1 添加一个依赖，并执行pod update

pod 'HAccessTools'

##### 9.1.2 在viewDidLoad中添加
```objectivec
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    [[HNetworkAutoMock shared] enable];
    [HNetworkAutoMock shared].baseformat = @{@"status":@YES};
});
```
###### 9.1.3 将SimpleDAO设置为mock模式，在init函数中添加
```objectivec
self.isMock = YES;
```
运行一下吧

运行起来报错了，原因是url不合法，看一下数据，原来是src不对.
我们可以看到数据，同时下发了url和fullImageURL,  我们用一下这个地址发现只有fullImageURL这是一个有效的图片地址
这是因为，在自动mock中，猜对了fullImageURL的值应该是啥样的，但是”url”的命名框架猜不出来。

对于自动mock，命名越准确，注解写的越准确，那么就越容易猜中。

我们这里暂时把fullImageURL改成“可选的”，以完成这个案例
ppx(fullImageURL, HPOptional)
运行一下吧.
##### 9.1.4 指定mock类型
如果框架猜测的结果不对，那么可以手动指定某一个属性mock成什么数据，例如
```
ppx(server_modified, HPMockAsDate)
ppx(server_created, HPMockAsDate)
```
这几个注解定义在“HNetworkAutoMock.h”中

对于多层次的model也是可用的, 在HAccessTools里面有更加清楚的demo
注意: 模拟数据的随机图片地址是可裁剪的，在将要发送图片请求时修改一下url
```objectivec
if ([url containsString:@"unsplash.it"])
{
    NSRange range = [url rangeOfString:@"image="];
    url = [NSString stringWithFormat:@"https://unsplash.it/%d/%d?%@",(int)w,(int)h, [url substringFromIndex:range.location]];
    return url;
}
```
占位符是显示区域宽高

### 9.2 手动Mock
不开启HNetworkAutoMock的情况下，打开isMock开关，则走手动mock
在项目中建立一个`HNetworkDAO.bundle`, 在里面建立`SimpleDAO同名`的一个json文件即可，在这个json文件里面就是手写json数据了

## 十.其他问题

a.文件上传见HNetworkMultiDataObj

b.请合理设计你的接口类继承关系

c.HDeserializableObject和HDatabaseDAO的可以直接参考HAccess的demo

d.HFileCache是一种扔进去就不用管了的缓存，见这个库的demo
