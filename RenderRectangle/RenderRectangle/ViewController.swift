//
//  ViewController.swift
//  RenderRectangle
//
//  Created by Emre Turgay on 13.01.2024.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    
    var metalView: MTKView {
           return view as! MTKView
       }
    override func loadView() {
        view = MTKView()
    }
    
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    
    
    struct Vertex {
        var position: vector_float4
        var color: vector_float4
    }
    let vertices: [Vertex] = [
        Vertex(position: [-0.5,  0.5, 0, 1], color: [0, 1, 0, 1]), // Top Left
        Vertex(position: [-0.5, -0.5, 0, 1], color: [0, 0, 1, 1]), // Bottom Left
        Vertex(position: [ 0.5, -0.5, 0, 1], color: [1, 0, 0, 1]), // Bottom Right
        Vertex(position: [ 0.5,  0.5, 0, 1], color: [1, 1, 0, 1])  // Top Right
    ]
    let indices: [UInt16] = [
        0, 1, 2,
        2, 3, 0
    ]

    
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        device = MTLCreateSystemDefaultDevice()
        metalView.device = device
        commandQueue = device.makeCommandQueue()
        
        metalView.delegate = self
        metalView.clearColor = MTLClearColor(red: 1, green: 1, blue: 0, alpha: 1) // White background
        
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

        // Set up the vertex buffer and draw
        let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // If using an index buffer:
        let indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.stride, options: [])
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer!, indexBufferOffset: 0)

        // If not using an index buffer, use drawPrimitives instead
        // renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)

        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

