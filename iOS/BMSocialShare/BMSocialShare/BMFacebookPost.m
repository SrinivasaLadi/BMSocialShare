//
//  BMFacebookPost.m
//  BMSocialShare
//
//  Created by Vinzenz-Emanuel Weber on 05.11.11.
//  Copyright (c) 2011 Blockhaus Medienagentur. All rights reserved.
//

#import "BMFacebookPost.h"


@interface BMFacebookPost() {
    BMFacebookPostType _type;
    NSMutableDictionary *_attachment;
    NSMutableDictionary *_media;
    NSMutableDictionary *_properties;
    UIImage *_image;
    NSString *_imageName;
    NSMutableDictionary *_params;
}

@end



@implementation BMFacebookPost

@synthesize type = _type, image = _image;


- (id)_initWithParams:(NSMutableDictionary *)params
{
    self = [super init];
    if (self) {
        _params = [params retain];
    }
    return self;
}


#pragma mark - Text Post


- (id)initWithTitle:(NSString *)title descriptionText:(NSString *)description andHref:(NSString *)href {
    
    if (self = [super init]) {
        
        _type = kPostText;
        _attachment = [[NSMutableDictionary alloc] init];
        
        if (title) {
            [_attachment setObject:title forKey:@"name"];
            
            if (href) {
                [_attachment setObject:href forKey:@"href"];
            }
        }
        
        if (description) {
            [_attachment setObject:description forKey:@"description"];
        }
        
        
    }
    return self;
    
}


- (void)addPropertyWithTitle:(NSString *)title descriptionText:(NSString *)description andHref:(NSString *)href {
    
    if (_properties == nil) {
        _properties = [[NSMutableDictionary alloc] init];
    }
    
    NSMutableDictionary *prop = [[NSMutableDictionary alloc] init];
    [prop setObject:description forKey:@"text"];
    [prop setObject:href forKey:@"href"];
    [_properties setObject:prop forKey:title];
    [prop release];
}


- (NSMutableDictionary *)_textParams {
    if (_properties != nil && _attachment != nil) {
        [_attachment setObject:_properties forKey:@"properties"];
    }
    
    SBJSON *jsonWriter = [[SBJSON new] autorelease];
    NSString *attachmentString = [jsonWriter stringWithObject:_attachment];
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            attachmentString, @"attachment", nil];
}


#pragma mark - Image Post


- (id)initWithImage:(UIImage *)image {
    if (self = [super init]) {
        _type = kPostImage;
        _image = image;
    }
    return self;
}

- (id)initWithImageNoDialog:(UIImage *)image withText:(NSString *)text {
    if (self = [super init]) {
        _type = kPostImageNoDialog;
        _image = image;
        _imageName = text;
    }
    return self;
}


- (void)setImageName:(NSString *)name {
    _imageName = name;
}


- (void)setImageUrl:(NSString *)imageUrl withHref:(NSString *)href{
    
    if (_media == nil) {
        _media = [[NSMutableDictionary alloc] init];        
    }
    
    [_media setObject:@"image" forKey:@"type"];
    [_media setObject:imageUrl forKey:@"src"];
    [_media setObject:href forKey:@"href"];
    [_attachment setObject:[NSArray arrayWithObject:_media] forKey:@"media"];  
}


- (NSMutableDictionary *)_imageParams {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:_image forKey:@"picture"];
    if (_imageName) {
        [params setObject:_imageName forKey:@"message"];
    }
    return params;
}


+ (NSString *)_cachedImageFilePath {
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *imageCacheFilePath = [cachesPath stringByAppendingPathComponent:kFacebookCachedImageFileName];
    return imageCacheFilePath;
}


#pragma mark - Post Params


- (NSMutableDictionary *)params {

    // we already restored the parmeter dictionary from NSUserDefaults
    if (_params) {
        return _params;
    }
    
    switch (_type) {
        
        case kPostImageNoDialog:
        {
            return [self _imageParams];
        }
            
        case kPostImage:
        {
            return [self _imageParams];
        }
            
        default:
        case kPostText:
        {
            return [self _textParams];
        }
            
    }
    
}


#pragma mark - Storage


- (void)storeToUserDefaults {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    switch (_type) {
            
        case kPostImage:
        {
            NSString *imageCacheFilePath = nil;
            if (_image) {
                NSData* imageData = UIImagePNGRepresentation(_image);
                imageCacheFilePath = [BMFacebookPost _cachedImageFilePath];
                NSLog(@"BMSocialShare: Caching image to be posted in %@", imageCacheFilePath);

                if([imageData writeToFile:imageCacheFilePath atomically:NO]) {
                    [defaults setInteger:_type forKey:kFacebookPostType];
                } else {
                    NSLog(@"BMSocialShare: Caching image failed!");
                }
            }
        }
            break;
            
            
        case kPostText:
        {
            [defaults setObject:[self _textParams] forKey:kFacebookPostParams];
            [defaults setInteger:_type forKey:kFacebookPostType];
        }
            break;
            
    }

    [defaults synchronize];
}


+ (BMFacebookPost *)postFromUserDefaults {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BMFacebookPostType postType = [defaults integerForKey:kFacebookPostType];
    
    switch (postType) {

        case kPostImage:
        {
            // let's restore the cached image
            NSString *cachedImageFilePath = [BMFacebookPost _cachedImageFilePath];
            if (cachedImageFilePath) {
                UIImage *image = [UIImage imageWithContentsOfFile:cachedImageFilePath];
                if (image) {
                    [defaults setInteger:0 forKey:kFacebookPostType];
                    BMFacebookPost *post = [[BMFacebookPost alloc] initWithImage:image];
                    return post;
                }
            }
        }
            break;

            
        case kPostText:
        {
            // is there a post that was created before we logged in?
            NSDictionary *params = [defaults dictionaryForKey:kFacebookPostParams];
            if (params) {
                BMFacebookPost *post = [[BMFacebookPost alloc] _initWithParams:[NSMutableDictionary dictionaryWithDictionary:params]];
                return post;
            }
            
        }
            break;

    }
    
    return nil;
}


/**
 * In case the user does not want to login to Facebook or
 * somehow is cancelling the post, we need to remove the post
 * from user defaults.
 */
+ (void)deleteLastPostFromUserDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kFacebookPostType];
    [defaults removeObjectForKey:kFacebookPostParams];
    [defaults synchronize];
}


#pragma mark - Memory Management


- (void)dealloc {
    [_attachment release];
    [_media release];
    [_properties release];
    [_image release];
    [_imageName release];
    [super dealloc];
}




@end
