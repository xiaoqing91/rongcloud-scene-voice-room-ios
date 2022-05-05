//
//  RCVideoRoomCell.m
//  RCSceneExample-Objc
//
//  Created by hanxiaoqing on 2022/4/26.
//

#import "RCVoiceRoomCell.h"
#import <SDWebImage/SDWebImage.h>

@implementation RCVoiceRoomCell

- (void)updateUI:(RCSceneRoomInfo *)roomInfo {
    _titleLabel.text = roomInfo.roomName;
    [_avatarView sd_setImageWithURL:[NSURL URLWithString:roomInfo.themePictureUrl]];
}

@end
