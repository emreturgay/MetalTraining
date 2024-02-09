//
//  Shader.metal
//  RenderImagePoints
//
//  Created by Emre Turgay on 21.01.2024.
//

#include <metal_stdlib>
using namespace metal;



struct VertexInOut {
    float4 position [[position]];
    float2 texCoords;
    float pointSize [[point_size]];    // ADDED
};


vertex VertexInOut vertexShader(uint vertexID [[vertex_id]],
                              constant VertexInOut *vertices [[buffer(0)]]) {
    
    return vertices[vertexID];
}



fragment float4 fragmentShader(VertexInOut in [[stage_in]],
                               texture2d<float> texture [[texture(0)]]) {
    
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    return texture.sample(textureSampler, in.texCoords);
}

