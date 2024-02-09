//
//  Ahder.metal
//  RenderRectangle
//
//  Created by Emre Turgay on 13.01.2024.
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


vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                             constant VertexIn *vertices [[buffer(0)]]) {
    
    VertexOut out;
    out.position = vertices[vertexID].position;
    out.color = vertices[vertexID].color;
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]]) {
    return in.color;
}
