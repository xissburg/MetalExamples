//
//  Shader.metal
//  Graphics
//
//  Created by xiss burg on 10/14/14.
//  Copyright (c) 2014 xissburg. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexInput {
    float2 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct VertexOutput {
    float4 position [[position]];
    float4 color;
};

vertex VertexOutput basic_vertex(VertexInput in [[stage_in]]) {
    VertexOutput out;
    out.position = float4(in.position, 0, 1);
    out.color = in.color;
    return out;
}

fragment float4 basic_fragment(VertexOutput in [[stage_in]]) {
    return in.color;
}
