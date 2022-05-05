#import "RCSceneVoiceRoomList.h"
#import <YYModel.h>

@implementation RCNetResponseWrapper

+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{@"data": [RCSceneVoiceRoomList class] };
}

@end


@implementation RCSceneVoiceRoomList

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    _rooms = [NSArray yy_modelArrayWithClass:[RCSceneRoomInfo class] json:dic[@"rooms"]];
    return YES;
}
@end

@implementation RCSceneRoomInfo
@end

@implementation RCSceneCreateUser
@end
