<h1 align="center"> 语聊房 </h>

<p align="center">
<a href="https://github.com/rongcloud/rongcloud-scene-voice-room-ios">
<img src="https://img.shields.io/cocoapods/v/RCSceneVoiceRoom.svg?style=flat">
</a>

<a href="https://github.com/rongcloud/rongcloud-scene-voice-room-ios">
<img src="https://img.shields.io/cocoapods/l/RCSceneVoiceRoom.svg?style=flat">
</a>

<a href="https://github.com/rongcloud/rongcloud-scene-voice-room-ios">
<img src="https://img.shields.io/cocoapods/p/RCSceneVoiceRoom.svg?style=flat">
</a>

<a href="https://github.com/rongcloud/rongcloud-scene-voice-room-ios">
<img src="https://img.shields.io/badge/%20in-swift%205-orange.svg">
</a>

</p>

## 简介

语聊房 demo 是融云场景化团队提供的开源项目，其中包含了主流业务常见的开播、连麦、麦位管理、房间管理等功能。

## 集成

### 使用 CocoaPods
1. 终端 cd 至项目根目录
2. 执行 pod init
3. 执行 open -e Podfile
4. 添加导入配置 pod 'RCSceneVoiceRoom'
5. 执行 pod install
6. 双击打开 .xcworkspace

### 创建房间

开发者一般调用业务服务器接口创建房间，这样服务器端可以维护房间列表和管理：
1. 编写房间信息，一般是业务 UI 完成（可选）
2. 调用服务器端接口创建房间（可选）
3. 根据房间信息初始化房间模型（必须）
4. 初始化房间视图控制器，传入房间数据模型（必须）
5. 房间视图展示（必须）

```
/// 这里是视图初始化和展示示例，信息编辑和房间创建，根据业务需求实现
let controller = RCVoiceRoomController(room: room, isCreate: true)
navigationController?.pushViewController(controller, animated: true)
```

### 加入房间

加入已创建的房间，需要通过房间信息模型初始化视图控制器：

```
let controller = RCVoiceRoomController(room: room)
navigationController?.pushViewController(controller, animated: true)
```

## 功能

模块             |  简介 |  示图
:-------------------------:|:-------------------------:|:-------------------------:
开启直播 | 主播说话，观众收听，支持房间内观众连麦，支持最多 8 个观众连麦，聊天室消息发送和展示等  |  <img width ="300" src="https://tva1.sinaimg.cn/large/e6c9d24ely1h182tc468fj20af0ijq4a.jpg">
房间音乐 | 基于 Hifive 实现音乐播放，需开通相关业务  |  <img width="200" src="https://tva1.sinaimg.cn/large/e6c9d24ely1h182xszyydj20af0ijq3v.jpg">
赠送礼物 | 支持单人、多人、全服礼物发送，需二次开发对接业务  |  <img width ="300" src="https://tva1.sinaimg.cn/large/e6c9d24ely1h182u9yw13j20af0ij0tq.jpg">
房间设置 | 包含常见的房间信息管理  |  <img width ="300" src="https://tva1.sinaimg.cn/large/e6c9d24ely1h182wvnukbj20af0ij75a.jpg">
跨房间PK | 支持 1v1 跨房间 PK，需要配合服务器实现  |  <img width ="300" src="https://tva1.sinaimg.cn/large/e6c9d24ely1h182xeppm1j20af0ijgmp.jpg">


## 其他
如有任何疑问请提交 issue
