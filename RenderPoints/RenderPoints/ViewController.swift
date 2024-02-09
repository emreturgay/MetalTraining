//
//  ViewController.swift
//  RenderPoints
//
//  Created by Emre Turgay on 15.01.2024.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    
    var metalView:MTKView!
    var device:MTLDevice!
    var commandQueue:MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!

    struct Vertex {
        var position: vector_float4
        var color: vector_float4
        var pointSize: Float
    }

    
    let gridSize = 10
    var quadVertices: [Vertex] = []
    var indices: [UInt16] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let yellowColor = vector_float4(1, 0, 0, 1) // Yellow color

        for y in 0..<gridSize {
            for x in 0..<gridSize {
                // Vertex position
                let xPos = Float(x) / Float(gridSize - 1) - 0.5
                let yPos = Float(y) / Float(gridSize - 1) - 0.5
                quadVertices.append(Vertex(position: [xPos, yPos, 0, 1], color: vector_float4(1 , 1, 0, 1), pointSize: 10.0))

                // Indices (skip the last row/column)
                if x < gridSize - 1 && y < gridSize - 1 {
                    let topLeft = y * gridSize + x
                    let topRight = topLeft + 1
                    let bottomLeft = topLeft + gridSize
                    let bottomRight = bottomLeft + 1

                    // First triangle - Top left, top right, bottom left
                    indices.append(UInt16(topLeft))
                    indices.append(UInt16(topRight))
                    indices.append(UInt16(bottomLeft))

                    // Second triangle - Top right, bottom right, bottom left
                    indices.append(UInt16(topRight))
                    indices.append(UInt16(bottomRight))
                    indices.append(UInt16(bottomLeft))
                }
            }
        }


        metalView = self.view as? MTKView
        device = MTLCreateSystemDefaultDevice()
        metalView.device = device
        
        metalView.delegate = self
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1) // White background
        //metalView.framebufferOnly = false
        commandQueue = device.makeCommandQueue()
        guard let library = device.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "vertexShader"),
              let fragmentFunction = library.makeFunction(name: "fragmentShader") else {
            fatalError("Unable to create Metal objects")
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError("Unable to create render pipeline state: \(error)")
        }
        
        
    }

}

extension ViewController: MTKViewDelegate {

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle view size changes if necessary
    }

    func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
            }
        
        let vertexBuffer = device.makeBuffer(bytes: quadVertices, length: quadVertices.count * MemoryLayout<Vertex>.stride, options: [])
         
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        
        let indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.stride, options: [])
        renderEncoder.setRenderPipelineState(pipelineState)
        //renderEncoder.drawIndexedPrimitives(type: .line, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer!, indexBufferOffset: 0)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: quadVertices.count, instanceCount: 1)


        // Create a command buffer and a render command encoder
        renderEncoder.endEncoding()

        // Present the drawable to the screen
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

