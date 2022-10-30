//
//  ViewController.m
//  RCSceneExample-Objc
//
//  Created by hanxiaoqing on 2022/4/26.
//

#import "HomeViewController.h"
#import "RCSceneVoiceRoomList.h"
#import "RCSceneExample_Objc-Swift.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "RCVoiceRoomCell.h"
#import <RCIM.h>

@interface HomeViewController () <UITableViewDelegate, UITableViewDataSource, VoiceRoomBridgeDelegate, RCIMConnectionStatusDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) UIRefreshControl *refreshControl;

@property (strong, nonatomic) NSArray *rooms;

@property (strong, nonatomic) VoiceRoomBridge *voiceRoomBridge;

@end

@implementation HomeViewController

- (VoiceRoomBridge *)voiceRoomBridge {
    if (!_voiceRoomBridge) {
        _voiceRoomBridge = [[VoiceRoomBridge alloc] init];
        _voiceRoomBridge.delegate = self;
    }
    return _voiceRoomBridge;
}

- (UIRefreshControl *)refreshControl {
    if (!_refreshControl) {
        _refreshControl = [UIRefreshControl new];
        [_refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    }
    return _refreshControl;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"融云-场景化-语聊房";
    self.tableView.refreshControl = self.refreshControl;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
    [self connection];
}

- (void)connection {
    if ([[RCIM sharedRCIM] getConnectionStatus] == ConnectionStatus_Connected) {
        return;
    }
    NSString *rcToken = [self.voiceRoomBridge userDefaultsSavedToken];
    if (rcToken.length == 0) {
        [self performSegueWithIdentifier:@"Login" sender:nil];
        return;
    }
    [[RCIM sharedRCIM] initWithAppKey:[AppConfigs getRCKey]];
    [[RCIM sharedRCIM] connectWithToken:rcToken dbOpened:^(RCDBErrorCode code) {
        NSLog(@"RCIM db open failed: %zd",code);
    } success:^(NSString *userId) {
        NSLog(@"userId: %@",userId);
        [self refresh];
    } error:^(RCConnectErrorCode errorCode) {
        NSLog(@"RCIM connect failed: %zd", errorCode);
    }];
}

- (IBAction)createRoom:(id)sender
{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"创建房间" message:nil preferredStyle: UIAlertControllerStyleAlert];
    [actionSheet addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"输入房间名字";
    }];
    UIAlertAction *createAction = [UIAlertAction actionWithTitle:@"创建房间" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *roomNameField = actionSheet.textFields[0];
                NSString *roomName = roomNameField.text;
        [self.voiceRoomBridge createRoomFromVc:self name:roomName];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [actionSheet addAction:createAction];
    [actionSheet addAction:cancelAction];
    [self presentViewController:actionSheet animated:YES completion:nil];
}


- (void)refresh {
    [self.voiceRoomBridge getRoomList];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    RCVoiceRoomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    [cell updateUI:self.rooms[indexPath.row]];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rooms.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RCSceneRoomInfo *roomInfo = self.rooms[indexPath.row];
    [self.voiceRoomBridge enterVoiceRoomFromVc:self roomId:roomInfo.roomId];
}


- (void)getRoomListCompletionWithResult:(NSArray<RCSceneRoomInfo *> *)result error:(NSError *)error {
    if (error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    } else {
        self.rooms = result;
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    }
}

#pragma mark - RCIMConnectionStatusDelegate -

- (void)onRCIMConnectionStatusChanged:(RCConnectionStatus)status {
    switch (status) {
        case ConnectionStatus_KICKED_OFFLINE_BY_OTHER_CLIENT:
            [LoginBridge logout];
            [self performSegueWithIdentifier:@"Login" sender:nil];
            break;
            
        default:
            break;
    }
}

@end
