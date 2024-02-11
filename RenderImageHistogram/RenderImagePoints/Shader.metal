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



// Metal Shader File (MyShaders.metal)

kernel void computeRedHistogram(
    texture2d<float, access::read> inputTexture [[texture(0)]],
    device atomic_uint* histogram [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    constexpr sampler imgSampler(coord::normalized, filter::nearest);
    float2 texCoord = float2(gid) / float2(inputTexture.get_width(), inputTexture.get_height());
    float4 pixelColor = inputTexture.read(gid);//.sample(imgSampler, texCoord);

    // Assuming the histogram has 256 bins for the 256 possible intensity values of the red channel
    uint binIndex = clamp(uint(pixelColor.b * 255.0f), 0u, 255u);
    atomic_fetch_add_explicit(&histogram[binIndex], 1, memory_order_relaxed);
}

kernel void computeHistogram(
    texture2d<float, access::read> inputTexture [[texture(0)]],
    device atomic_uint* histogramRGB [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    float4 pixelColor = inputTexture.read(gid);

    // Assuming the histogram has 256 bins for the 256 possible intensity values of the red channel
    uint binIndexR = clamp(uint(pixelColor.r * 255.0f), 0u, 255u);
    uint binIndexG = clamp(uint(pixelColor.g * 255.0f), 0u, 255u);
    uint binIndexB = clamp(uint(pixelColor.b * 255.0f), 0u, 255u);
    atomic_fetch_add_explicit(&histogramRGB[binIndexR], 1, memory_order_relaxed);
    atomic_fetch_add_explicit(&histogramRGB[binIndexG + 256], 1, memory_order_relaxed);
    atomic_fetch_add_explicit(&histogramRGB[binIndexB + 512], 1, memory_order_relaxed);
}

vertex VertexInOut vertexShaderHistogram(uint vertexID [[vertex_id]],
                              constant VertexInOut *vertices [[buffer(0)]],
                                texture2d<float> texture [[texture(0)]],
                                         constant ShaderUniforms& params [[ buffer(1) ]]) {
    
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest);
    float4 pixelColor = texture.sample(textureSampler, vertices[vertexID].texCoords);
    
    texture.sample(textureSampler,vertices[vertexID].texCoords);
        
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

