//
//  ViewController.m
//  TestApp
//
//  Created by Антон Кузнецов on 19/02/16.
//  Copyright © 2016 thelightprj. All rights reserved.
//

#import "LoginViewController.h"
#import "SocketClient.h"

@interface LoginViewController ()

@property (nonatomic, strong) IBOutlet UITextField *emailField;
@property (nonatomic, strong) IBOutlet UITextField *passwordField;
@property (nonatomic, strong) IBOutlet UIButton *loginButton;
@property (nonatomic, strong) IBOutlet UIView *activityOverlay;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *scrollViewBottomConstraint;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:self.view.window];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:self.view.window];
    
    _loginButton.layer.cornerRadius = 6;
}
#pragma mark - User Actions

- (IBAction)loginButtonAction:(id)sender {
    _activityOverlay.hidden = NO;
    
    [[SocketClient shared] loginWithEmail:_emailField.text
                                 password:_passwordField.text
                          completionBlock:^(BOOL success, NSDictionary *response) {
                              _activityOverlay.hidden = YES;
                              if (success) {
                                  NSLog(@"Yes");
                              } else {
                                  NSString *description = @"Something went wrong";
                                  if (response != nil && [response isKindOfClass:[NSDictionary class]]) {
                                      description = response[@"error_description"];
                                  }
                                  
                                  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                      message:description
                                                                                     delegate:nil
                                                                            cancelButtonTitle:@"Dismiss"
                                                                            otherButtonTitles: nil];
                                  [alertView show];
                                  
                                  NSLog(@"No");
                              }
                          }];
}

#pragma mark - Notifications


- (void)keyboardWillHide:(NSNotification *)notification {
    _scrollViewBottomConstraint.constant = 0;
    
    [_scrollView setNeedsUpdateConstraints];
    [self.view setNeedsDisplay];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary* userInfo = [notification userInfo];
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    _scrollViewBottomConstraint.constant = keyboardSize.height;
    
    [_scrollView setNeedsUpdateConstraints];
    [self.view setNeedsDisplay];
}

@end
