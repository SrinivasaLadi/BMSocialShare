//
//  BMFacebookPost.h
//  BMSocialShare
//
//  Created by Vinzenz-Emanuel Weber on 05.11.11.
//  Copyright (c) 2011 Blockhaus Medienagentur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SBJSON.h"



#define kFacebookPostParams             @"BMSocialShareFacebookPostParams"
#define kFacebookPostType               @"BMSocialShareFacebookPostType"
#define kFacebookCachedImageFileName    @"BMSocialShareFacebookPostImage"



typedef enum {
    kPostText = 1001,
    kPostImage = 1002
} BMFacebookPostType;


@interface BMFacebookPost : NSObject


@property (nonatomic, readonly) NSMutableDictionary *params;
@property (nonatomic, readonly) BMFacebookPostType type;
@property (nonatomic, readonly) UIImage *image;


/**
 * In case you need to post to your user's wall and maybe want to include
 * an image from some URL, you should be using the following methods.
 */
- (id)initWithTitle:(NSString *)title descriptionText:(NSString *)description andHref:(NSString *)href;
- (void)setImageUrl:(NSString *)imageUrl withHref:(NSString *)href;
- (void)addPropertyWithTitle:(NSString *)title descriptionText:(NSString *)description andHref:(NSString *)href;

/**
 * In case you need to post an image to your user's album, init this
 * class with an image.
 */
- (id)initWithImage:(UIImage *)image;
- (void)setImageName:(NSString *)name;

/**
 * If the user is not logged in yet, we need to store the current post
 * until he returns. In SSO login usually the Facebook app is opened
 * for verification. When the user returns the facebook dialog shoul reappear.
 */
- (void)storeToUserDefaults;
+ (BMFacebookPost *)postFromUserDefaults;
+ (void)deleteLastPostFromUserDefaults;


@end
