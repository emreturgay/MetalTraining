//
//  Shader.metal
//  RenderMultipleObjects
//
//  Created by Emre Turgay on 17.01.2024.
//
#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[position]];
    float4 color;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

struct Uniforms {
    float4 color;
    float2 positionShift;
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                             constant VertexIn *vertices [[buffer(0)]],
                              constant Uniforms &uniforms [[buffer(1)]]) {
    
    VertexOut out;
    out.position = vertices[vertexID].position;
    out.position[0] += uniforms.positionShift[0];
    out.position[1] += uniforms.positionShift[1];
    out.color = vertices[vertexID].color;
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               constant Uniforms &uniforms [[buffer(1)]]) {
    float4 color = in.color + uniforms.color;
    return color;
}

