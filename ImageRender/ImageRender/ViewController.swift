//
//  ViewController.swift
//  ImageRender
//
//  Created by Emre Turgay on 12.01.2024.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    
    var metalView:MTKView!
    var device:MTLDevice!
    var commandQueue:MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var texture: MTLTexture?
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


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        metalView = self.view as? MTKView
        device = MTLCreateSystemDefaultDevice()
        metalView.device = device
        
        metalView.delegate = self
        metalView.framebufferOnly = false
        commandQueue = device.makeCommandQueue()
        
        loadTexture()
        
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
        
        if let image = UIImage(named: "barina.jpg"),
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
        let indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.size, options: [])
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(texture, index: 0)        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer!, indexBufferOffset: 0)

        // Create a command buffer and a render command encoder
        renderEncoder.endEncoding()

        // Present the drawable to the screen
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

