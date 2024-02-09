//
//  ViewController.swift
//  Triangle
//
//  Created by Emre Turgay on 11.01.2024.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    
    
    var metalView: MTKView!
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        metalView = self.view as? MTKView
        device = MTLCreateSystemDefaultDevice()
        metalView.device = device
        
        
        metalView.delegate = self
        metalView.framebufferOnly = false
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
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)


        // Create a command buffer and a render command encoder
        renderEncoder.endEncoding()

        // Present the drawable to the screen
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}


