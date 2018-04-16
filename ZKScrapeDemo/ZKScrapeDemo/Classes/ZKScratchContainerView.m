//
//  ZKScratchContainerView.m
//  ZKScrapeDemo
//
//  Created by Zhou Kang on 2018/4/13.
//  Copyright © 2018年 Zhou Kang Inc. All rights reserved.
//

#import "ZKScratchContainerView.h"
#import "UIImage+Addition.h"
#import "ZKScratchImageView.h"
#import <Masonry.h>
#import "ConfigHeader.h"
#import <YYKit.h>
#import "NSTimer+ZKAutoRelease.h"

@interface ZKScratchContainerView () <ZKScratchImageViewDelegate>

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) ZKScratchImageView *maskImageView;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSMutableArray <ZKScratchItem *> *dataSource;
@property (nonatomic, weak)   NSTimer *timer;
@property (nonatomic, assign) NSInteger resumeTime;

@end

@implementation ZKScratchContainerView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initData];
        [self setup];
    }
    return self;
}

- (void)addTimer {
    __weak typeof(self) weakSelf = self;
    _timer = [NSTimer zk_scheduledTimerWithTimeInterval:2 block:^{
        if (++ weakSelf.resumeTime % 2 == 0) {
            NSLog(@"恢复模糊");
            [weakSelf.maskImageView resume];
        }
    } repeates:true];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)stopTimer {
    [_timer invalidate];
    _timer = nil;
}

- (void)updateWithDataSource:(NSArray<ZKScratchItem *> *)items {
    [_dataSource addObjectsFromArray:items];
    _imageView.image = [self getOriginalImageWithIndex:_currentIndex];
    [self startRender];
    [self addTimer];
}

- (void)startRender {
    if (_currentIndex >= _dataSource.count) {
        return;
    }
    
    ZKScratchItem *item = _dataSource[_currentIndex];
    
    UIImage *oriImage = [self getOriginalImageWithIndex:_currentIndex];
    CGRect blurRect = item.blurRect;
    UIImage *blurImage = [oriImage imageClipedWithRect:blurRect];
    blurImage = [blurImage imageByBlurSoft];
    [_maskImageView setImage:blurImage radius:3.f];
    _maskImageView.alpha = .95;
    
    CGFloat scale = [self calcScale];
    
    if ([self isImageWidderThanScreenWidth:oriImage]) {
        CGFloat deltaY = (SCREEN_HEIGHT - oriImage.size.height * scale) * .5;
        _maskImageView.frame = (CGRect){
            blurRect.origin.x * scale,
            blurRect.origin.y * scale + deltaY,
            blurRect.size.width * scale,
            blurRect.size.height * scale };
    }
    else {
        CGFloat deltaX = (SCREEN_WIDTH - oriImage.size.width * scale) * .5;
        _maskImageView.frame = (CGRect){
            blurRect.origin.x * scale + deltaX,
            blurRect.origin.y * scale,
            blurRect.size.width * scale,
            blurRect.size.height * scale };
    }
}

- (void)initData {
    _dataSource = [NSMutableArray array];
}

- (void)setup {
    _imageView = [[UIImageView alloc] init];
    [self addSubview:_imageView];
    [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.userInteractionEnabled = true;
    
    _maskImageView = [[ZKScratchImageView alloc] init];
    [_imageView addSubview:_maskImageView];
    _maskImageView.delegate = self;
    _maskImageView.layer.cornerRadius = 10.f;
    _maskImageView.layer.masksToBounds = true;
    _maskImageView.alpha = .98;
}

- (CGFloat)calcScale {
    UIImage *targetImage = [self getOriginalImageWithIndex:_currentIndex];
    CGSize imageSize = [targetImage size];
    BOOL isWidder = [self isImageWidderThanScreenWidth:targetImage];
    
    CGFloat scale = 0;
    if (isWidder) {
        scale = SCREEN_WIDTH / imageSize.width;
    }
    else {
        scale = SCREEN_HEIGHT / imageSize.height;
    }
    return scale;
}

- (BOOL)isImageWidderThanScreenWidth:(UIImage *)image {
    CGSize imageSize = image.size;
    BOOL isWidder = imageSize.width / imageSize.height > SCREEN_WIDTH / SCREEN_HEIGHT;
    return isWidder;
}

- (UIImage *)getOriginalImageWithIndex:(NSInteger)index {
    if (index >= _dataSource.count) {
        return nil;
    }
    ZKScratchItem *item = _dataSource[index];
    UIImage *image = [UIImage imageNamed:item.imageName];
    return image;
}

#pragma mark - <ZKScratchImageViewDelegate>

- (void)scratchImageView:(ZKScratchImageView *)scratchImageView didChangeMaskingProgress:(CGFloat)maskingProgress {
    NSLog(@"%f", maskingProgress);
}

- (void)dealloc {
    [self stopTimer];
}

@end
