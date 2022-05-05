//
//  RCVideoRoomCell.h
//  RCSceneExample-Objc
//
//  Created by hanxiaoqing on 2022/4/26.
//

#import <UIKit/UIKit.h>
#import "RCSceneVoiceRoomList.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCVoiceRoomCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarView;

- (void)updateUI:(RCSceneRoomInfo *)roomInfo;

@end

NS_ASSUME_NONNULL_END
