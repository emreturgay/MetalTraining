//
//  shader.metal
//  ConvertToGrayScale
//
//  Created by Emre Turgay on 24.02.2024.
//
#include <metal_stdlib>
using namespace metal;


typedef struct {
    float4 position [[position]];
    float2 texcoord;
} VertexOut;

vertex VertexOut vertexShader(uint vertexID [[vertex_id]]) {
    const float4 positions[6] = {
        float4(-1.0,  1.0, 0.0, 1.0), // Top Left
        float4(-1.0, -1.0, 0.0, 1.0), // Bottom Left
        float4( 1.0, -1.0, 0.0, 1.0), // Bottom Right
        float4(-1.0,  1.0, 0.0, 1.0), // Top Left
        float4( 1.0, -1.0, 0.0, 1.0), // Bottom Right
        float4( 1.0,  1.0, 0.0, 1.0)  // Top Right
    };
    const float2 texcoords[6] = {
        float2(0.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0),
        float2(0.0, 1.0),
        float2(1.0, 0.0),
        float2(1.0, 1.0)
    };

    VertexOut out;
    out.position = positions[vertexID];
    out.texcoord = texcoords[vertexID];
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               texture2d<float> texture [[texture(0)]]) {
    constexpr sampler textureSampler(coord::normalized, address::clamp_to_edge, filter::linear);
    float4 color = texture.sample(textureSampler, in.texcoord);
    return color;
}



// Define a kernel function to convert image to grayscale
kernel void convertToGrayscale(texture2d<float, access::sample> inTexture [[texture(0)]],
                               texture2d<float, access::write> outTexture [[texture(1)]],
                               uint2 gid [[thread_position_in_grid]])
{
    constexpr sampler textureSampler(coord::normalized, address::clamp_to_edge, filter::linear);

    
    const uint downsampleFactor = 2;
    uint2 sampledPosition = gid * downsampleFactor;
    
    if (sampledPosition.x >= inTexture.get_width() || sampledPosition.y >= inTexture.get_height()) {
         return;
    }
    
    // Calculate normalized texture coordinates
    float2 texCoords = float2(gid) / float2(inTexture.get_width(), inTexture.get_height());
    
    
    float4 pixelColor = inTexture.read(sampledPosition);

    // Sample the input texture
   // float4 pixelColor = inTexture.sample(textureSampler, texCoords);

    // Calculate the grayscale value using the luminosity method
    float grayscale = dot(pixelColor.rgb, float3(0.299, 0.587, 0.114));

    // Write the grayscale value to the output texture
    outTexture.write(float4(grayscale, grayscale, grayscale, pixelColor.a), gid);
}
