//
//  ViewController.m
//  Compute
//
//  Created by xiss burg on 10/14/14.
//  Copyright (c) 2014 xissburg. All rights reserved.
//

#import "ViewController.h"
@import Metal;

void ImageProviderReleaseData(void *info, const void *data, size_t size);

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLComputePipelineState> pipeline;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setup];
    
    [self filterImage:[UIImage imageNamed:@"AMG_GT"] completion:^(UIImage *filteredImage) {
        self.imageView.image = filteredImage;
    }];
}

- (void)setup
{
    self.device = MTLCreateSystemDefaultDevice();
    
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    id<MTLFunction> grayscaleFunction = [library newFunctionWithName:@"grayscale"];
    
    self.commandQueue = [self.device newCommandQueue];
    
    NSError *error = nil;
    self.pipeline = [self.device newComputePipelineStateWithFunction:grayscaleFunction error:&error];
    
    if (self.pipeline == nil) {
        NSLog(@"Failed to create pipeline: %@", error);
    }
}

- (void)filterImage:(UIImage *)image completion:(void (^)(UIImage *filteredImage))completion
{
    CGImageRef CGImage = image.CGImage;
    NSUInteger width = CGImageGetWidth(CGImage);
    NSUInteger height = CGImageGetHeight(CGImage);
    NSUInteger bitsPerComponent = 8;
    NSUInteger bytesPerRow = width * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst|kCGBitmapByteOrder32Little);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), CGImage);
    GLubyte *textureData = (GLubyte *)CGBitmapContextGetData(context);
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:width height:height mipmapped:NO];
    id<MTLTexture> inputTexture = [self.device newTextureWithDescriptor:textureDescriptor];
    id<MTLTexture> outputTexture = [self.device newTextureWithDescriptor:textureDescriptor];
    
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    [inputTexture replaceRegion:region mipmapLevel:0 withBytes:textureData bytesPerRow:bytesPerRow];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    id <MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    id <MTLComputeCommandEncoder> commandEncoder = [commandBuffer computeCommandEncoder];
    [commandEncoder setComputePipelineState:self.pipeline];
    [commandEncoder setTexture:inputTexture atIndex:0];
    [commandEncoder setTexture:outputTexture atIndex:1];
    
    MTLSize threadsPerGroup = MTLSizeMake(16, 16, 1);
    MTLSize numThreadgroups = MTLSizeMake(width/threadsPerGroup.width, height/threadsPerGroup.height, 1);
    [commandEncoder dispatchThreadgroups:numThreadgroups threadsPerThreadgroup:threadsPerGroup];
    [commandEncoder endEncoding];
    
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> cb) {
        size_t size = width * height * 4;
        void *bytes = malloc(size);
        [outputTexture getBytes:bytes bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, bytes, size, ImageProviderReleaseData);
        CGImageRef cgImage = CGImageCreate(width, height, bitsPerComponent, bitsPerComponent * 4, bytesPerRow, colorSpace, bitmapInfo, provider, NULL, FALSE, kCGRenderingIntentDefault);
        CGDataProviderRelease(provider);
        
        UIImage *filteredImage = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        CGColorSpaceRelease(colorSpace);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(filteredImage); 
        });
    }];
    [commandBuffer commit];
}

@end

void ImageProviderReleaseData(void *info, const void *data, size_t size)
{
    free((void *)data);
}
