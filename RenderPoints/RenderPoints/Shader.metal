//
//  Shader.metal
//  RenderPoints
//
//  Created by Emre Turgay on 15.01.2024.
//

#include <metal_stdlib>
using namespace metal;



struct VertexInOut {
    float4 position [[position]];
    float4 color;
    float pointSize [[point_size]];    // ADDED
};


vertex VertexInOut vertexShader(uint vertexID [[vertex_id]],
                              constant VertexInOut *vertices [[buffer(0)]]) {
    
    VertexInOut out;
    out.position = vertices[vertexID].position;
    out.color = vertices[vertexID].color;
    out.pointSize = vertices[vertexID].pointSize;                    // ADDED
    return vertices[vertexID];
}



fragment float4 fragmentShader(VertexInOut in [[stage_in]]) {
    return in.color;
    }


