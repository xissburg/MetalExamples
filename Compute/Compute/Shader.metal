//
//  Shader.metal
//  Compute
//
//  Created by xiss burg on 10/14/14.
//  Copyright (c) 2014 xissburg. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void grayscale(texture2d<float, access::read> inputTexture [[texture(0)]],
                      texture2d<float, access::write> outputTexture [[texture(1)]],
                      uint2 gid [[thread_position_in_grid]])
{
    float4 color = inputTexture.read(gid);
    float gray = dot(color.xyz, float3(0.3, 0.59, 0.11));
    outputTexture.write(float4(gray), gid);
}