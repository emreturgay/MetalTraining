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
    var commandQueue: MTLCommandQueue!
    
    var metalView : MTKView!
    var pipelineState: MTLRenderPipelineState!
    var pipelineStateHistGen: MTLRenderPipelineState!
    var pipelineStateCompute: MTLComputePipelineState!
    var textureLenna: MTLTexture?
    var textureOffscreen: MTLTexture?
    var textureTest: MTLTexture?
    var pixelDataBuffer: MTLBuffer! = nil
    var bufferSize: Int = 0
    var histogramBufferRGB: MTLBuffer!
    
    struct Vertex {
        var position: vector_float4
        var texCoords: vector_float2
        var pointSize: Float
    }

    struct ShaderUniforms {
        var channel: Int;
        var channelMask: vector_float4;
    };
    
    
    let gridSize = 128
    var quadVertices: [Vertex] = []
    var indices: [UInt16] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //init device
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        
        
        //init view
        metalView = self.view as? MTKView
        metalView.device = device
        metalView.delegate = self
        
        // create geometry
        for y in 0..<gridSize {
            for x in 0..<gridSize {
                // Vertex position
                let xPos = 2.0 * Float(x) / Float(gridSize - 1) - 1.0
                let yPos = 2.0 * Float(y) / Float(gridSize - 1) - 1.0
                let uPos = Float(x) / Float(gridSize - 1)
                let vPos = Float(y) / Float(gridSize - 1)
                quadVertices.append(Vertex(position: [xPos, yPos, 0, 1], texCoords: vector_float2(uPos, vPos), pointSize: 1.0))

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
        createOffScreenTexture()
        textureTest = createColorTexture(device: device)
        createPixelBuffer()
        
        
        

        // init pipilene for Histogram Generation Stage
        guard let library = device.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "vertexShaderHistogram"),
              let fragmentFunction = library.makeFunction(name: "fragmentShaderHistogram") else {
            fatalError("Unable to create Metal objects")
        }

        let pipelineDescriptorHistGen = MTLRenderPipelineDescriptor()
        pipelineDescriptorHistGen.vertexFunction = vertexFunction
        pipelineDescriptorHistGen.fragmentFunction = fragmentFunction
        pipelineDescriptorHistGen.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        pipelineDescriptorHistGen.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptorHistGen.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptorHistGen.colorAttachments[0].sourceRGBBlendFactor = .one
        pipelineDescriptorHistGen.colorAttachments[0].destinationRGBBlendFactor = .one

        do {
            pipelineStateHistGen = try device.makeRenderPipelineState(descriptor: pipelineDescriptorHistGen)
        } catch let error {
            fatalError("Unable to create render pipeline state: \(error)")
        }
        
        // init pipilene for Final Stage
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
        
        // init computeshader pipeine state
        
        guard let library = device.makeDefaultLibrary(),
              let function = library.makeFunction(name: "computeHistogram")
        else {
            fatalError("Unable to create Metal objects")
        }
        do {
            pipelineStateCompute = try device.makeComputePipelineState(function: function)
        }catch let error {
            fatalError("Unable to create render pipeline state: \(error)")
        }
        // Initialize histogram buffer with 256 bins set to 0
        histogramBufferRGB = device.makeBuffer(length: 3 * 256 * MemoryLayout<UInt32>.size, options: .storageModeShared)
        memset(histogramBufferRGB.contents(), 0, 3 * 256 * MemoryLayout<UInt32>.size)
        
        
        let startTime = Date()
        computeHistogram(for: textureLenna!)
        // Calculate the elapsed time
        let elapsedTime = Date().timeIntervalSince(startTime)

        // Print the elapsed time in seconds
        print("Elapsed time: \(elapsedTime) seconds")
        
    }
        
    func createOffScreenTexture()
    {
        // Create the offscreen texture
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm, // Choose an appropriate format
            width: 256,
            height: 1,
            mipmapped: false
        )
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        textureOffscreen = device.makeTexture(descriptor: textureDescriptor)
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
    
    func createPixelBuffer(){
        bufferSize = (textureOffscreen?.width ?? 256) * (textureOffscreen?.height ?? 256) * 4 // 4 bytes per pixel for BGRA
        pixelDataBuffer = device.makeBuffer(length: bufferSize, options: .storageModeShared)!
    }
    
    struct Pixel {
        var r: UInt8;
        var g: UInt8;
        var b: UInt8;
        var a: UInt8;
        init(_ r: UInt8, _ g: UInt8, _ b: UInt8, _ a: UInt8) {
                self.r = r
                self.g = g
                self.b = b
                self.a = a
            }
    }
    func createColorTexture(device: MTLDevice) -> MTLTexture? {
        
        let numRow = 256
        let numCol = 256
        
        var pixelData: [Pixel] = []

        let step = UInt8(255 / (numCol - 1)) // Calculate the step for red channel increase
        for row in 0..<numRow { // for each row
            for col in 0..<60 { // for each column
                let redValue = step * UInt8((row + col) / 2) // Calculate red value for the column
                pixelData.append(Pixel(redValue, redValue/2, redValue/2 + 125, 255)) // Append pixel with the calculated red value
            }
            for col in 60..<105 { // for each column
                pixelData.append(Pixel(128, 70, 170, 255)) // Append pixel with the calculated red value
            }
            for col in 105..<160 { // for each column
                pixelData.append(Pixel(138, 100, 50, 255)) // Append pixel with the calculated red value
            }
            for col in 160..<195 { // for each column
                pixelData.append(Pixel(148, 140, 100, 255)) // Append pixel with the calculated red value
            }
            for col in 195..<256 { // for each column
                let redValue = step * UInt8((row + col) / 2) // Calculate red value for the column
                pixelData.append(Pixel(redValue, redValue/2, redValue/2 + 125, 255)) // Append pixel with the calculated red value
            }
        }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: numCol,
            height: numRow,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            fatalError("Failed to create texture")
        }
        
        texture.replace(region: MTLRegionMake2D(0, 0, numCol, numRow),
                        mipmapLevel: 0,
                        withBytes: pixelData,
                        bytesPerRow: 4 * numCol)
        
        return texture
    }
  
    
    func computeHistogram(for texture: MTLTexture) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        
        computeEncoder.setComputePipelineState(pipelineStateCompute)
        computeEncoder.setTexture(texture, index: 0)
        computeEncoder.setBuffer(histogramBufferRGB, offset: 0, index: 0)
        
        let threadGroupSize = MTLSize(width: 8, height: 8, depth: 1) // Example size, adjust based on your texture
        let threadGroups = MTLSize(width: (texture.width + threadGroupSize.width - 1) / threadGroupSize.width,
                                   height: (texture.height + threadGroupSize.height - 1) / threadGroupSize.height,
                                   depth: 1)
        
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        // At this point, the histogramBuffer contains the histogram data
        // You can read it back to the CPU to process or display it
        
        let histogramDataPointer = histogramBufferRGB.contents().bindMemory(to: UInt32.self, capacity: 256 * 3)
        let histogramData = Array(UnsafeBufferPointer(start: histogramDataPointer, count: 256 * 3))
        // Now you have the histogram data as an array of UInt32
        // Print the histogram data
        for (index, value) in histogramData.enumerated() {
            print("Bin \t \(index) \t \(value)")
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
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0,1.0)
        
        guard
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        
        let vertexBuffer = device.makeBuffer(bytes: quadVertices, length: quadVertices.count * MemoryLayout<Vertex>.stride, options: [])
        
        // Create a buffer for the parameters
        var shaderParams = ShaderUniforms(channel: 2, channelMask: vector_float4(1.0, 0.0, 0.0, 1.0))
        let paramsBuffer = device.makeBuffer(bytes: &shaderParams,
                                             length: MemoryLayout<ShaderUniforms>.size,
                                             options: [])
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(paramsBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentBuffer(paramsBuffer, offset: 0, index: 1)
        
        renderEncoder.setFragmentTexture(textureLenna, index: 0)
        renderEncoder.setVertexTexture(textureLenna, index: 0)
        renderEncoder.setRenderPipelineState(pipelineStateHistGen)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: quadVertices.count, instanceCount: 1)
        
        renderEncoder.endEncoding()
        commandBuffer.commit()
        
        guard
              let commandBuffer = device.makeCommandQueue()!.makeCommandBuffer()
        else {
            return
        }
        
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
        blitEncoder.copy(from: textureOffscreen!,
                         sourceSlice: 0,
                         sourceLevel: 0,
                         sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                         sourceSize: MTLSize(width: textureOffscreen!.width, height: textureOffscreen!.height, depth: 1),
                         to: pixelDataBuffer,
                         destinationOffset: 0,
                         destinationBytesPerRow: textureOffscreen!.width * 4,
                         destinationBytesPerImage: textureOffscreen!.width * textureOffscreen!.height * 4)
        
        blitEncoder.endEncoding()


        
        commandBuffer.addCompletedHandler { [self] _ in
            let data = Data(bytesNoCopy: pixelDataBuffer.contents(), count: self.bufferSize, deallocator: .none)
            
            // Now you can process 'data' to read the pixel values
            // Example: Print the first 10 pixels' data
            let bytesPerPixel = 4
            for i in 0..<textureOffscreen!.width {
                let index = i * bytesPerPixel
                guard index + 3 < data.count else { break }

                let b = data[index]
                let g = data[index + 1]
                let r = data[index + 2]
                let a = data[index + 3]

                //print("Pixel \(i): (R: \t \(r) \t  G: \t \(g) \t  B: \t \(b) ")
                
                print("Pixel \t  \(i) \t \(r)")
            }
        }
        commandBuffer.commit()

        
        
        
        // second stage
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = device.makeCommandQueue()!.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(textureTest, index: 0)
        
        let indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.stride, options: [])
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer!, indexBufferOffset: 0)
        

        // Create a command buffer and a render command encoder
        renderEncoder.endEncoding()

        // Present the drawable to the screen
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
}

