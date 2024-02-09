//
//  ViewController.swift
//  TwoStagePipeline
//
//  Created by Emre Turgay on 23.01.2024.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    

    var device: MTLDevice!
    var metalView: MTKView!
    
    var textureLenna: MTLTexture?
    var textureOffscreen: MTLTexture?
    
    var pipelineState1: MTLRenderPipelineState!
    
    var pipelineState2: MTLRenderPipelineState!
    

    struct Vertex {
        var position: vector_float4
        var texCoords: vector_float2
    }

    let quadVertices: [Vertex] = [
        Vertex(position: [-0.5,  0.5, 0, 1], texCoords: [0, 1]), // Top Left
        Vertex(position: [-0.5, -0.5, 0, 1], texCoords: [0, 0]), // Bottom Left
        Vertex(position: [ 0.5, -0.5, 0, 1], texCoords: [1, 0]), // Bottom Right
        Vertex(position: [ 0.5,  0.5, 0, 1], texCoords: [1, 1])  // Top Right
    ]

    let indices: [UInt16] = [
        2, 3, 0,
        0, 1, 2
    ]

    
    func loadTexture() {
        guard let device = device else { return }

        let textureLoader = MTKTextureLoader(device: device)
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [.origin: MTKTextureLoader.Origin.bottomLeft]
        
        if let image = UIImage(named: "Lenna.png"),
           let cgImage = image.cgImage {
            do {
                textureLenna = try textureLoader.newTexture(cgImage: cgImage, options: textureLoaderOptions)
            } catch {
                print("Texture loading error: \(error)")
            }
        }
        else{
            print("can not open image")
        }
    }
    
    func createOffScreenTexture()
    {
        // Create the offscreen texture
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm, // Choose an appropriate format
            width: 256,
            height: 256,
            mipmapped: false
        )
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        textureOffscreen = device.makeTexture(descriptor: textureDescriptor)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        
        metalView = self.view as? MTKView
        metalView.device = device
        metalView.delegate = self
        
       
        
        
        metalView.clearColor = MTLClearColor(red: 0.2, green: 0, blue: 0, alpha: 1) // red background
        metalView.framebufferOnly = false
        loadTexture()
        createOffScreenTexture()
        
        
        //Create Pipeline State for Stage 1
        guard let library = device.makeDefaultLibrary(),
              let vertexFunction1 = library.makeFunction(name: "vertexShader"),
              let fragmentFunction1 = library.makeFunction(name: "fragmentShader") else {
            fatalError("Unable to create Metal objects")
        }
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction1
        pipelineDescriptor.fragmentFunction = fragmentFunction1
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        do {
            pipelineState1 = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError("Unable to create render pipeline state1: \(error)")
        }
        
        
        //Create Pipeline State for Stage 2
        guard let vertexFunction2 = library.makeFunction(name: "vertexShader"),
              let fragmentFunction2 = library.makeFunction(name: "fragmentShader2") else {
            fatalError("Unable to create Metal objects")
        }
        
        
        let pipelineDescriptor2 = MTLRenderPipelineDescriptor()
        pipelineDescriptor2.vertexFunction = vertexFunction2
        pipelineDescriptor2.fragmentFunction = fragmentFunction2
        pipelineDescriptor2.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        do {
            pipelineState2 = try device.makeRenderPipelineState(descriptor: pipelineDescriptor2)
        } catch let error {
            fatalError("Unable to create render pipeline state2: \(error)")
        }
        
        
    }
    
   
}

extension ViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        
        // Create the render pass descriptor
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = textureOffscreen
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 0, 1)

        
        guard
              let commandBuffer = device.makeCommandQueue()!.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        let vertexBuffer = device.makeBuffer(bytes: quadVertices, length: quadVertices.count * MemoryLayout<Vertex>.stride, options: [])
     
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        let indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.stride, options: [])
        renderEncoder.setRenderPipelineState(pipelineState1)
        
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer!, indexBufferOffset: 0)
      
        renderEncoder.endEncoding()
        commandBuffer.commit()
        
       
        // Stage 2
        
        
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor2 = view.currentRenderPassDescriptor,
              let commandBuffer2 = device.makeCommandQueue()!.makeCommandBuffer(),
              let renderEncoder2 = commandBuffer2.makeRenderCommandEncoder(descriptor: renderPassDescriptor2) else {
            return
        }
                 
        
        renderPassDescriptor2.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 1.0, 1.0, 1.0)
        renderPassDescriptor2.colorAttachments[0].loadAction = .clear
        
        renderEncoder2.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder2.setFragmentTexture(textureOffscreen, index: 0)
        renderEncoder2.setRenderPipelineState(pipelineState2)
        renderEncoder2.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer!, indexBufferOffset: 0)
        
        
         
        // Create a command buffer and a render command encoder
        renderEncoder2.endEncoding()

        // Present the drawable to the screen
        commandBuffer2.present(drawable)
        commandBuffer2.commit()
         
    }
    
}

