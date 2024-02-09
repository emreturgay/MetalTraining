//
//  Shaders.metal
//  TwoStagePipeline
//
//  Created by Emre Turgay on 23.01.2024.
//

#include <metal_stdlib>
using namespace metal;



struct VertexInOut {
    float4 position [[position]];
    float2 texCoords;
};


vertex VertexInOut vertexShader(uint vertexID [[vertex_id]],
                              constant VertexInOut *vertices [[buffer(0)]]) {
    VertexInOut out;
    out.position = vertices[vertexID].position;
    out.texCoords = vertices[vertexID].texCoords;
    return out;
}



fragment float4 fragmentShader(VertexInOut in [[stage_in]]) {
    return float4(0.0, 1.0, 1.0, 1.0);
}

fragment float4 fragmentShader2(VertexInOut in [[stage_in]],
                               texture2d<float> texture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    return texture.sample(textureSampler, in.texCoords);
    }




