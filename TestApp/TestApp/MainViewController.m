//
//  MainViewController.m
//  TestApp
//
//  Created by Антон Кузнецов on 19/02/16.
//  Copyright © 2016 thelightprj. All rights reserved.
//

#import "MainViewController.h"
#import "SocketClient.h"

@interface MainViewController ()

@property (nonatomic, strong) IBOutlet UILabel *tokenLabel;
@property (nonatomic, strong) IBOutlet UILabel *expirationLabel;
@property (nonatomic, strong) IBOutlet UIButton *logoutButton;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _logoutButton.layer.cornerRadius = 6;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    
    SocketClient *client = [SocketClient shared];
    
    _expirationLabel.text = [dateFormatter stringFromDate:client.expirationDate];
    _tokenLabel.text = client.currentToken;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - User Action

- (IBAction)logOutAction:(id)sender {
    [[SocketClient shared] logout];
}

@end
