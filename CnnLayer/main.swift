// We are a way for the cosmos to know itself. -- C. Sagan

import Foundation
import MetalPerformanceShaders

func demonstrateFutility() {
    let device = MTLCopyAllDevices()[0]

    let inputs: [Float] = ([Int](0..<42)).map { _ in Float(Bool.random() ? 1 : 1) }

    let inputRegion = MTLRegionMake2D(0, 0, 7, 6)
    let outputRegion = MTLRegionMake2D(0, 0, 6, 5)

    let hotMess = HotMess()

    let source1Image = hotMess.setupSourceImage(device: device, width: 7, height: 6)
    let destinationImage = hotMess.setupDestinationImage(device: device, width: 6, height: 5)

    hotMess.setupInputs(inputs, inputImage: source1Image, region: inputRegion, elementsPerRow: 7)

//    let weights = SwiftPointer(Float.self, elements: 42 * 30)
//    weights.getMutableBufferPointer().assign(repeating: 1)

//    let ds = hotMess.setupDataSource(width: 42, height: 30, weights: weights)
//    let fucerometer = MPSCNNFullyConnected(device: device, weights: ds)
//
//    fucerometer.clipRect.size.width = 4
//    fucerometer.clipRect.size.height = 4

//    let myWeights = SwiftPointer<Float>(Float.self, elements: 16)
//    myWeights.getMutableBufferPointer().assign(repeating: 1)
//    let ds = hotMess.setupDataSource(width: 4, height: 4, weights: myWeights)
//    let convolometer = hotMess.setupConvolution(device: device, width: 4, height: 4, dataSource: ds)

    let poolerometer = MPSCNNPoolingMax(device: device, kernelWidth: 4, kernelHeight: 4)
    poolerometer.offset.x = 1
    poolerometer.offset.y = 1
    poolerometer.edgeMode = .zero

    let commandQueue = device.makeCommandQueue()!
    let commandBuffer = commandQueue.makeCommandBuffer()!

    poolerometer.encode(
        commandBuffer: commandBuffer, sourceImage: source1Image,
        destinationImage: destinationImage
    )

//    convolometer.encode(commandBuffer: commandBuffer, sourceImage: source1Image, destinationImage: destinationImage)

    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    print("inputs", inputs)
    let outputs = hotMess.getOutputs(from: destinationImage, region: outputRegion, width: 6, height: 5)
    print("outputs \(outputs.map { Float($0 * 1) })")
}

demonstrateFutility()
