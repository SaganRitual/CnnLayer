// We are a way for the cosmos to know itself. -- C. Sagan

import Foundation
import MetalPerformanceShaders

func demonstrateFutility() {
    let device = MTLCopyAllDevices()[0]

    let width = 3
    let height = 2

    let inputs: [Float] = .init(repeating: 1, count: width * height)
    let weights_: [Float] = .init(repeating: 1, count: width * height)

    let weights = SwiftPointer(Float.self, elements: weights_.count)
    weights.raw.initializeMemory(as: Float.self, from: weights_, count: weights_.count)

    let region = MTLRegionMake2D(0, 0, width, height)

    let hotMess = HotMess()

    let dataSource = hotMess.setupDataSource(width: width, height: height, weights: weights)
    let sourceImage = hotMess.setupSourceImage(device: device, width: width, height: height)
    let destinationImage = hotMess.setupDestinationImage(device: device, width: width, height: height)
    let convolution = hotMess.setupConvolution(device: device, width: width, height: height, dataSource: dataSource)

    hotMess.setupInputs(inputs, inputImage: sourceImage, region: region, elementsPerRow: width)

    let commandQueue = device.makeCommandQueue()!
    let commandBuffer = commandQueue.makeCommandBuffer()!

    convolution.encode(
        commandBuffer: commandBuffer,
        sourceImage: sourceImage, destinationImage: destinationImage
    )

    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    let outputs = hotMess.getOutputs(from: destinationImage, region: region, width: width, height: height)
    print("outputs \(outputs)")
}

demonstrateFutility()
