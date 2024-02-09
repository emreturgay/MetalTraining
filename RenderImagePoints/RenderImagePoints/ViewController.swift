//
//  ViewController.swift
//  RenderImagePoints
//
//  Created by Emre Turgay on 21.01.2024.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    
    
    var device : MTLDevice!
    var metalView : MTKView!
    var pipelineState: MTLRenderPipelineState!
    var texture: MTLTexture?
    
    struct Vertex {
        var position: vector_float4
        var texCoords: vector_float2
        var pointSize: Float
    }

    let gridSize = 128
    var quadVertices: [Vertex] = []
    var indices: [UInt16] = []
    /*
    let quadVertices: [Vertex] = [
        Vertex(position: [-0.5,  0.5, 0, 1], texCoords: [0, 1], pointSize: 1.0), // Top Left
        Vertex(position: [-0.5, -0.5, 0, 1], texCoords: [0, 0], pointSize: 1.0), // Bottom Left
        Vertex(position: [ 0.5, -0.5, 0, 1], texCoords: [1, 0], pointSize: 1.0), // Bottom Right
        Vertex(position: [ 0.5,  0.5, 0, 1], texCoords: [1, 1], pointSize: 1.0)  // Top Right
    ]

    let indices: [UInt16] = [
        2, 3, 0,
        0, 1, 2
    ]
    
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //init device
        device = MTLCreateSystemDefaultDevice()
        
        
        //init view
        metalView = self.view as? MTKView
        metalView.device = device
        metalView.delegate = self
        
        // create geometry
        
  
        
        
        for y in 0..<gridSize {
            for x in 0..<gridSize {
                // Vertex position
                let xPos = Float(x) / Float(gridSize - 1) - 0.5
                let yPos = Float(y) / Float(gridSize - 1) - 0.5
                quadVertices.append(Vertex(position: [xPos, yPos, 0, 1], texCoords: vector_float2(xPos + 0.5, yPos + 0.5), pointSize: 1.0))

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
        
        
        
        loadTexture()

        // init pipilene
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
    
    func loadTexture() {
        guard let device = device else { return }

        let textureLoader = MTKTextureLoader(device: device)
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [.origin: MTKTextureLoader.Origin.bottomLeft]
        
        if let image = UIImage(named: "Lenna.png"),
           let cgImage = image.cgImage {
            do {
                texture = try textureLoader.newTexture(cgImage: cgImage, options: textureLoaderOptions)
            } catch {
                print("Texture loading error: \(error)")
            }
        }
        else{
            print("can not open image")
        }
    }
    
    func renderToOffscreenTexture() {
        // Create the offscreen texture
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm, // Choose an appropriate format
            width: 256,
            height: 256,
            mipmapped: false
        )
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        guard let offscreenTexture = device.makeTexture(descriptor: textureDescriptor) else {
            return
        }

        // Create the render pass descriptor
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = offscreenTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0.5, 0, 1)

        // Render
        guard let commandBuffer = device.makeCommandQueue()!.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        let vertexBuffer = device.makeBuffer(bytes: quadVertices, length: quadVertices.count * MemoryLayout<Vertex>.stride, options: [])
    
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setVertexTexture(texture, index: 0)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: quadVertices.count, instanceCount: 1)

        renderEncoder.endEncoding()
        commandBuffer.commit()

        // Now `offscreenTexture` contains the rendered content
    }

        


}


extension ViewController: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = device.makeCommandQueue()!.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        let vertexBuffer = device.makeBuffer(bytes: quadVertices, length: quadVertices.count * MemoryLayout<Vertex>.stride, options: [])
    
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setVertexTexture(texture, index: 0)
        let indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.stride, options: [])
        renderEncoder.setRenderPipelineState(pipelineState)
        //renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer!, indexBufferOffset: 0)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: quadVertices.count, instanceCount: 1)


        // Create a command buffer and a render command encoder
        renderEncoder.endEncoding()

        // Present the drawable to the screen
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
}

