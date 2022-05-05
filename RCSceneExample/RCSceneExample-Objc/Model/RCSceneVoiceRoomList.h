// RCSceneVoiceRoomList.h

#import <Foundation/Foundation.h>

@class RCSceneVoiceRoomList;
@class RCSceneRoomInfo;
@class RCSceneCreateUser;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Object interfaces

@interface RCNetResponseWrapper : NSObject
@property (nonatomic, assign) NSInteger code;
@property (nonatomic, strong) RCSceneVoiceRoomList *data;
@property (nonatomic, copy)   NSString *msg;
@end

@interface RCSceneVoiceRoomList : NSObject
@property (nonatomic, copy)   NSArray *images;
@property (nonatomic, copy)   NSArray<RCSceneRoomInfo *> *rooms;
@property (nonatomic, assign) NSInteger totalCount;
@end

@interface RCSceneRoomInfo : NSObject
@property (nonatomic, copy)   NSString *backgroundURL;
@property (nonatomic, strong) RCSceneCreateUser *createUser;
@property (nonatomic, copy)   NSString *currentTime;
@property (nonatomic, copy)   NSString *gameName;
@property (nonatomic, assign) NSInteger identifier;
@property (nonatomic, assign) NSInteger isPrivate;
@property (nonatomic, copy)   NSString *password;
@property (nonatomic, copy)   NSString *roomId;
@property (nonatomic, copy)   NSString *roomName;
@property (nonatomic, assign) NSInteger roomType;
@property (nonatomic, assign) BOOL isStop;
@property (nonatomic, copy)   NSString *stopEndTime;
@property (nonatomic, copy)   NSString *themePictureUrl;
@property (nonatomic, copy)   NSString *updateDt;
@property (nonatomic, copy)   NSString *userID;
@property (nonatomic, assign) NSInteger userTotal;
@end

@interface RCSceneCreateUser : NSObject
@property (nonatomic, copy) NSString *portrait;
@property (nonatomic, copy) NSString *sex;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *userName;
@end

NS_ASSUME_NONNULL_END
