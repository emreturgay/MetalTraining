//
//  ViewController.swift
//  ConvertToGrayScale
//
//  Created by Emre Turgay on 24.02.2024.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    
    
    
    var device : MTLDevice!
    var commandQueue: MTLCommandQueue!
    var renderPipelineState: MTLRenderPipelineState!
    
    var metalView : MTKView!
    var textureLenna: MTLTexture?
    var textureLennaGray: MTLTexture?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //init device
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        
        
        //init view
        metalView = self.view as? MTKView
        metalView.device = device
        metalView.delegate = self
        
        loadTexture()
        
        textureLennaGray = convertImageToGrayscale(device: device, commandQueue: commandQueue, inputImage: textureLenna!)
        setupRenderPipeline()
        
    }
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
    
    
    func convertImageToGrayscale(device: MTLDevice, commandQueue: MTLCommandQueue, inputImage: MTLTexture) -> MTLTexture? {
        // Load the .metal shader file and create a compute pipeline state
        let library = device.makeDefaultLibrary()
        let kernelFunction = library?.makeFunction(name: "convertToGrayscale")
        guard let computePipelineState = try? device.makeComputePipelineState(function: kernelFunction!) else { return nil }
        
        // Create the output texture with the same size as the input image
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: inputImage.pixelFormat,
                                                                         width: inputImage.width,
                                                                         height: inputImage.height,
                                                                         mipmapped: false)
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        guard let outputTexture = device.makeTexture(descriptor: textureDescriptor) else { return nil }
        
        // Create and configure the command buffer and encoder
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return nil }
        computeEncoder.setComputePipelineState(computePipelineState)
        computeEncoder.setTexture(inputImage, index: 0)
        computeEncoder.setTexture(outputTexture, index: 1)
        
        // Calculate the thread group size and count
        let threadGroupSize = MTLSize(width: 8, height: 8, depth: 1) // Choose an optimal size based on your GPU
        let threadGroups = MTLSize(width: (inputImage.width/4 + threadGroupSize.width - 1) / threadGroupSize.width,
                                   height: (inputImage.height/4 + threadGroupSize.height - 1) / threadGroupSize.height,
                                   depth: 1)
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()
        
        // Commit the command buffer and wait for it to complete
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return outputTexture
    }
    
    func setupRenderPipeline() {
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        
        // Try to create the pipeline
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            print("Failed to create render pipeline state: \(error)")
        }
    }
}


extension ViewController: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setFragmentTexture(textureLennaGray, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}


