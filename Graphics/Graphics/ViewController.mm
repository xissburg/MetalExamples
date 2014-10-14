//
//  ViewController.mm
//  Graphics
//
//  Created by xiss burg on 10/14/14.
//  Copyright (c) 2014 xissburg. All rights reserved.
//

#import "ViewController.h"

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <simd/simd.h>

typedef struct {
    simd::float2 position;
    simd::float4 color;
} Vertex;

@interface ViewController ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipeline;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) CAMetalLayer *metalLayer;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.device = MTLCreateSystemDefaultDevice();
    
    self.metalLayer = [CAMetalLayer layer];
    self.metalLayer.device = self.device;
    self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    self.metalLayer.framebufferOnly = YES;
    self.metalLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.metalLayer];
    
    Vertex vertices[3];
    vertices[0].position = { 0,  0.5}, vertices[0].color = {1, 0, 0, 1};
    vertices[1].position = {-0.5, -0.5},  vertices[1].color = {0, 1, 0, 1};
    vertices[2].position = { 0.5, -0.5},   vertices[2].color = {0, 0, 1, 1};
    self.vertexBuffer = [self.device newBufferWithBytes:vertices length:sizeof(vertices) options:0];
    
    MTLVertexDescriptor *vertexDescriptor = [[MTLVertexDescriptor alloc] init];
    [vertexDescriptor.attributes objectAtIndexedSubscript:0].format = MTLVertexFormatFloat2;
    [vertexDescriptor.attributes objectAtIndexedSubscript:0].bufferIndex = 0;
    [vertexDescriptor.attributes objectAtIndexedSubscript:0].offset = offsetof(Vertex, position);
    [vertexDescriptor.attributes objectAtIndexedSubscript:1].format = MTLVertexFormatFloat4;
    [vertexDescriptor.attributes objectAtIndexedSubscript:1].bufferIndex = 0;
    [vertexDescriptor.attributes objectAtIndexedSubscript:1].offset = offsetof(Vertex, color);
    [vertexDescriptor.layouts objectAtIndexedSubscript:0].stride = sizeof(Vertex);
    [vertexDescriptor.layouts objectAtIndexedSubscript:0].stepFunction = MTLVertexStepFunctionPerVertex;
    
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    id<MTLFunction> vertexFunction = [library newFunctionWithName:@"basic_vertex"];
    id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"basic_fragment"];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.vertexDescriptor = vertexDescriptor;
    pipelineDescriptor.vertexFunction = vertexFunction;
    pipelineDescriptor.fragmentFunction = fragmentFunction;
    [pipelineDescriptor.colorAttachments objectAtIndexedSubscript:0].pixelFormat = self.metalLayer.pixelFormat;
    
    NSError *error = nil;
    self.pipeline = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    
    if (self.pipeline == nil) {
        NSLog(@"Failed to create pipeline: %@", error);
        return;
    }
    
    self.commandQueue = [self.device newCommandQueue];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)render
{
    id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
    
    MTLRenderPassDescriptor *renderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
    MTLRenderPassColorAttachmentDescriptor *colorAttachment = [renderPassDescriptor.colorAttachments objectAtIndexedSubscript:0];
    colorAttachment.texture = drawable.texture;
    colorAttachment.loadAction = MTLLoadActionClear;
    colorAttachment.clearColor = MTLClearColorMake(0, 0.4, 0.02, 1);
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder setRenderPipelineState:self.pipeline];
    [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [commandEncoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

@end
