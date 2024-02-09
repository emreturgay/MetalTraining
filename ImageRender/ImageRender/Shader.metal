//
//  Shader.metal
//  ImageRender
//
//  Created by Emre Turgay on 12.01.2024.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[position]];
    float2 texCoords;
};

typedef struct {
    float4 position [[position]];
    float2 texCoords;
} VertexOut;



vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                              constant VertexIn *vertices [[buffer(0)]]) {
    VertexOut out;
    out.position = vertices[vertexID].position;
    out.texCoords = vertices[vertexID].texCoords;
    return out;
}



fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               texture2d<float> texture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    return texture.sample(textureSampler, in.texCoords);
    }

