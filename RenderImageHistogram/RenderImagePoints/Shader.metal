//
//  Shader.metal
//  RenderImagePoints
//
//  Created by Emre Turgay on 21.01.2024.
//

#include <metal_stdlib>
using namespace metal;

struct ShaderUniforms {
    int channel;
    float4 channelMask;
};

struct VertexInOut {
    float4 position [[position]];
    float2 texCoords;
    float pointSize [[point_size]];    // ADDED
};


vertex VertexInOut vertexShaderHistogram(uint vertexID [[vertex_id]],
                              constant VertexInOut *vertices [[buffer(0)]],
                                texture2d<float> texture [[texture(0)]],
                                         constant ShaderUniforms& params [[ buffer(1) ]]) {
    
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest);
    float4 pixelColor = texture.sample(textureSampler, vertices[vertexID].texCoords);
        
    VertexInOut out;
    out.position = vertices[vertexID].position;
    float offset = 1.0 / 256.0;
    
    if (params.channel == 0)
        out.position.x = 2 * (pixelColor.x - 0.5) + offset;
    if (params.channel == 1)
        out.position.x = 2 * (pixelColor.y - 0.5) + offset;
    if (params.channel == 2)
        out.position.x = 2 * (pixelColor.z - 0.5) + offset;
    out.position.y = 0;
    out.texCoords = vertices[vertexID].texCoords;
    out.pointSize = vertices[vertexID].pointSize;                    // ADDED
    return out;
}



fragment float4 fragmentShaderHistogram(VertexInOut in [[stage_in]],
                                        constant ShaderUniforms& params [[ buffer(1) ]]) {
    return params.channelMask * 0.002;
}


vertex VertexInOut vertexShader(uint vertexID [[vertex_id]],
                              constant VertexInOut *vertices [[buffer(0)]]) {
    VertexInOut out;
    out.position = vertices[vertexID].position;
    out.texCoords = vertices[vertexID].texCoords;
    return out;
}



fragment float4 fragmentShader(VertexInOut in [[stage_in]],
                               texture2d<float> texture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest);
    return texture.sample(textureSampler, in.texCoords);
}

