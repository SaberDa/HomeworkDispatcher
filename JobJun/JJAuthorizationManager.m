//
//  Authorization.m
//  Joker
//
//  Created by Apple on 16/5/14.
//  Copyright © 2016年 猫儿出墙. All rights reserved.
//

#import "JJAuthorizationManager.h"
#import <AVOSCloud.h>
#import <AVOSCloudSNS.h>
#import <AVUser+SNS.h>

@implementation JJAuthorizationManager

+ (BOOL)automaticLogon {
    __block BOOL isSuccess = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *isLogin = [defaults objectForKey:@"isLogin"];
    if ([isLogin isEqualToString:@"YES"]) {
        NSString *name = [defaults objectForKey:@"userName"];
        NSString *password = [defaults objectForKey:@"password"];
        [self signInWithUserName:name password:password callBack:^(BOOL succeeded, NSError *error) {
            if (!succeeded) {
                isSuccess = NO;
            }
        }];
    } else {
        isSuccess = NO;
    }
    return isSuccess;
}

+ (void)thirdPartySignInWithPlateform:(JKSNSType)plateform callBack:(JKBooleanResultBlock)block {
    [AVOSCloudSNS loginWithCallback:^(id object, NSError *error) {
        if (error) {
            NSLog(@"SNS登录失败");
            block(NO, error);
        } else {
            NSString *plateformString = nil;
            switch (plateform) {
                case 1:
                    plateformString = @"weibo";
                    break;
                case 2:
                    plateformString = @"qq";
                    break;
                case 3:
                    plateformString = @"weixin";
                    break;
                default:
                    break;
            }
            [AVUser loginWithAuthData:object platform:plateformString block:^(AVUser *user, NSError *error) {
                if (error) {
                    block(NO, error);
                } else {
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setObject:user.username forKey:@"userName"];
                    [defaults setObject:user.objectId forKey:@"objectId"];
                    [defaults setObject:user.password forKey:@"password"];
                    [defaults setObject:@"YES" forKey:@"isLogin"];
                }
            }];
        }
    } toPlatform:(AVOSCloudSNSType)plateform];
}

+ (void)signInWithUserName:(NSString *)name password:(NSString *)password callBack:(JKBooleanResultBlock)block {
    [AVUser logInWithUsernameInBackground:name password:password block:^(AVUser *user, NSError *error) {
        if (error) {
            NSLog(@"登录出错");
            block(NO, error);
        } else {
            if (user) {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:user.username forKey:@"userName"];
                [defaults setObject:user.objectId forKey:@"objectId"];
                [defaults setObject:user.password forKey:@"password"];
                [defaults setObject:@"YES" forKey:@"isLogin"];
            } else {
                NSLog(@"账号不存在");
                block(NO, error);
            }
        }
    }];
}

+ (void)registerWithUserName:(NSString *)name andPassword:(NSString *)password callBack:(JKBooleanResultBlock)block {
    AVUser *user = [[AVUser alloc] init];
    user.username = name;
    user.password = password;
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [JJAuthorizationManager signInWithUserName:name password:password callBack:^(BOOL succeeded, NSError *error) {
                if (error) {
                    block(NO, error);
                }
            }];
        } else {
            NSLog(@"注册失败");
            block(NO, error);
        }
    }];
}


+ (void)LoginOut {
    [AVUser logOut];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"NO" forKey:@"isLogin"];
    [defaults removeObjectForKey:@"userName"];
    [defaults removeObjectForKey:@"password"];
    [defaults removeObjectForKey:@"objectId"];
}

+ (void)changPasswordFrom:(NSString *)oldPassword to:(NSString *)newPassword callBack:(AVIdResultBlock)block {
    AVUser *currentUser = [AVUser currentUser];
    [currentUser updatePassword:oldPassword newPassword:newPassword block:^(id object, NSError *error) {
        if (!error) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:newPassword forKey:@"password"];
        } else {
            NSLog(@"修改密码失败");
            block(object, error);
        }
    }];
}

+ (void)findUsersByIDs:(NSArray *)userIDs callBack:(JKArrayResultBlock)block {
    AVQuery *q = [AVUser query];
    [q whereKey:@"objectId" containedIn:userIDs];
    [q findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        block(objects, error);
    }];
}

+ (void)findUsersByPartname:(NSString *)name callBack:(JKArrayResultBlock)block {
    AVQuery *q = [AVUser query];
    [q setCachePolicy:kAVCachePolicyNetworkElseCache];
    [q whereKey:@"username" containsString:name];
    AVUser *curUser = [AVUser currentUser];
    [q whereKey:@"objectId" notEqualTo:curUser.objectId];
    [q orderByDescending:@"updatedAt"];
    [q findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        block(objects, error);
    }];
}

@end
