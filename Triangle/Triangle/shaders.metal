//
//  shaders.metal
//  Triangle
//
//  Created by Emre Turgay on 11.01.2024.
//

#include <metal_stdlib>
using namespace metal;

typedef struct {
    float4 position [[position]];
    float4 color;
} VertexOut;

vertex VertexOut vertexShader(uint vertexID [[vertex_id]]) {
    const float4 vertices[] = {
        float4( 0.0,  1.0, 0.0, 1.0), // Top Middle
        float4(-1.0, -1.0, 0.0, 1.0), // Bottom Left
        float4( 1.0, -1.0, 0.0, 1.0)  // Bottom Right
    };

    const float4 colors[] = {
        float4(0.0, 1.0, 0.0, 1.0), // Green
        float4(0.0, 1.0, 0.0, 1.0), // Green
        float4(0.0, 1.0, 0.0, 1.0)  // Green
    };

    VertexOut out;
    out.position = vertices[vertexID];
    out.color = colors[vertexID];
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]]) {
    return in.color;
}

