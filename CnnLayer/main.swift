// We are a way for the cosmos to know itself. -- C. Sagan

import Foundation
import MetalPerformanceShaders

print("Hello, World!")

let device = MTLCopyAllDevices()[0]

let width = 2
let height = 1

let widthCBytes = width * MemoryLayout<Float>.size
let heightCBytes = height * MemoryLayout<Float>.size

let imageCBytes = widthCBytes * heightCBytes
let imageCElements = width * height

let convolutionDescriptor = MPSCNNConvolutionDescriptor(
    kernelWidth: width, kernelHeight: height,
    inputFeatureChannels: 1, outputFeatureChannels: 1, neuronFilter: nil
)

let weights: [Float] = [1, 1, 1, 1]
// 0000 -> [0, 0, 0, 0]
// 0001 -> [1, 0, 0, 0] Bit 0 -> (0, 0)
// 0010 -> [1, 1, 0, 0] Bit 1 -> y == 0
// 0011 -> [2, 1, 0, 0]
// 0100 -> [1, 0, 1, 0] Bit 2 -> x == 0
// 0101 -> [2, 0, 1, 0]
// 0110 -> [2, 1, 1, 0]
// 0111 -> [3, 1, 1, 0]
// 1000 -> [1, 1, 1, 1] Bit 3 -> all
// 1001 -> [2, 1, 1, 1]
// 1010 -> [2, 2, 1, 1]
// 1011 -> [3, 2, 1, 1]
// 1100 -> [2, 1, 2, 1]
// 1101 -> [3, 1, 2, 1]
// 1110 -> [3, 2, 2, 1]
// 1111 -> [4, 2, 2, 1]

let pWeights = SwiftPointer(Float.self, elements: imageCElements)
pWeights.raw.initializeMemory(as: Float.self, from: weights, count: weights.count)

let dataSource = DataSourceCnn(
    biases: nil, weights: pWeights.raw, convolutionDescriptor: convolutionDescriptor
)

let convolution = MPSCNNConvolution(device: device, weights: dataSource)

convolution.offset = MPSOffset(x: width / 2, y: height / 2, z: 0)

let sourceImageDescriptor = MPSImageDescriptor(
    channelFormat: .float16, width: width, height: height, featureChannels: 1
)

let sourceImage = MPSImage(device: device, imageDescriptor: sourceImageDescriptor)

let region = MTLRegionMake2D(0, 0, width, height)

let inputsArray: [Float] = [1, 1, 1, 1]
// 0000 -> [0, 0, 0, 0]
// 0001 -> [1, 1, 1, 1] 1000        Bit 0 -> all
// 0010 -> [1, 0, 1, 0] 0100        Bit 1 -> x == 0
// 0011 -> [2, 1, 2, 1] 1100
// 0100 -> [1, 1, 0, 0] 0001        Bit 2 -> y == 0
// 0101 -> [2, 2, 1, 1] 0101
// 0110 -> [2, 1, 1, 0] 1001
// 0111 -> [3, 2, 2, 1] 1101
// 1000 -> [1, 0, 0, 0] 0010        Bit 3 -> (0, 0)
// 1001 -> [2, 1, 1, 1] 0110
// 1010 -> [2, 0, 1, 0] 1010
// 1011 -> [3, 1, 2, 1] 1110
// 1100 -> [2, 1, 0, 0] 0011
// 1101 -> [3, 2, 1, 1] 0111
// 1110 -> [3, 1, 1, 0] 1011
// 1111 -> [4, 2, 2, 1] 1111

let inputs32 = SwiftPointer(Float.self, elements: imageCElements)
inputs32.raw.initializeMemory(as: Float.self, from: inputsArray, count: imageCElements)

let inputs16 = SwiftPointer(UInt16.self, elements: imageCElements)

Float16.floats_to_float16s(input: inputs32.raw, output: inputs16.getMutableBufferPointer())

sourceImage.texture.replace(
    region: region, mipmapLevel: 0, withBytes: inputs16.getRawPointer(), bytesPerRow: max(4, widthCBytes)
)

let destinationImageDescriptor = MPSImageDescriptor(
    channelFormat: .float16, width: width, height: height, featureChannels: 1
)

let destinationImage = MPSImage(device: device, imageDescriptor: destinationImageDescriptor)
destinationImageDescriptor.usage = .shaderWrite

let commandQueue = device.makeCommandQueue()!
let commandBuffer = commandQueue.makeCommandBuffer()!

convolution.encode(
    commandBuffer: commandBuffer,
    sourceImage: sourceImage, destinationImage: destinationImage
)

commandBuffer.commit()
commandBuffer.waitUntilCompleted()

let outputs16 = SwiftPointer(UInt16.self, elements: imageCElements)
let outputs32 = SwiftPointer(Float.self, elements: imageCElements)

destinationImage.texture.getBytes(outputs16.raw, bytesPerRow: max(4, widthCBytes), from: region, mipmapLevel: 0)

let finalOutput = Float16.float16s_to_floats(values: outputs16.getArray())

print("outputs \(finalOutput.map { $0 })")
