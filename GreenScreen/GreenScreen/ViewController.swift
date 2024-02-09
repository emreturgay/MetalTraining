//
//  ViewController.swift
//  GreenScreen
//
//  Created by Emre Turgay on 23.01.2024.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    var metalView: MTKView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        metalView = self.view as? MTKView
        metalView.device = MTLCreateSystemDefaultDevice()
        
        
        metalView.delegate = self
        metalView.framebufferOnly = false
    }


}

extension ViewController: MTKViewDelegate {

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle view size changes if necessary
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }

        // Set the clear color to green
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 1.0, 0.0, 1.0)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear

        // Create a command buffer and a render command encoder
        let commandBuffer = view.device!.makeCommandQueue()!.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.endEncoding()

        // Present the drawable to the screen
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}



