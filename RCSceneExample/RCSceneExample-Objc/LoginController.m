//
//  LoginViewController.m
//  RCSceneExample-Objc
//
//  Created by hanxiaoqing on 2022/4/27.
//

#import "LoginController.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "RCSceneExample_Objc-Swift.h"

@interface LoginController () <LoginBridgeDelegate>

@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (strong, nonatomic) LoginBridge *loginBridge;

@end

@implementation LoginController

- (LoginBridge *)loginBridge {
    if (!_loginBridge) {
        _loginBridge = [[LoginBridge alloc] init];
        _loginBridge.delegate = self;
    }
    return _loginBridge;
}


- (void)viewDidLoad {
    [super viewDidLoad];
     
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.phoneTextField becomeFirstResponder];
}

- (IBAction)login:(id)sender {
    if (_phoneTextField.text.length < 11) {
        [SVProgressHUD showErrorWithStatus:@"请输入正确手机号"];
        return;
    }
    [self.loginBridge loginWithMobile:_phoneTextField.text];
}


- (void)loginCompletionWithResult:(NSString * _Nullable)result error:(NSError * _Nullable)error {
    if (error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}



@end
