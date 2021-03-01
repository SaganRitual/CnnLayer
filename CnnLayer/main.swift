// We are a way for the cosmos to know itself. -- C. Sagan

import Foundation
import MetalPerformanceShaders

func demonstrateFutility() {
    let device = MTLCopyAllDevices()[0]

    let primaryImageInputs: [Float] = ([Int](0..<42)).map { Float($0) }
    let secondaryImageInputs: [Float] = ([Int](0..<42)).map { _ in 1 }

    let primaryInputRegion = MTLRegionMake2D(0, 0, 7, 6)
    let secondaryInputRegion = MTLRegionMake2D(0, 0, 7, 6)
    let destinationRegion = MTLRegionMake2D(0, 0, 7, 6)

    let hotMess = HotMess()

    let primaryImage = hotMess.setupSourceImage(device: device, width: 7, height: 6)
    let secondaryImage = hotMess.setupSourceImage(device: device, width: 7, height: 6)
    let destinationImage = hotMess.setupDestinationImage(device: device, width: 7, height: 6)

    hotMess.setupInputs(primaryImageInputs, inputImage: primaryImage, region: primaryInputRegion, elementsPerRow: 7)
    hotMess.setupInputs(secondaryImageInputs, inputImage: secondaryImage, region: secondaryInputRegion, elementsPerRow: 7)

    let multerometer = MPSCNNMultiply(device: device)

    let commandQueue = device.makeCommandQueue()!
    let commandBuffer = commandQueue.makeCommandBuffer()!

    multerometer.encode(
        commandBuffer: commandBuffer, primaryImage: primaryImage,
        secondaryImage: secondaryImage, destinationImage: destinationImage
    )

    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    print("inputs", primaryImageInputs)
    let outputs = hotMess.getOutputs(from: destinationImage, region: destinationRegion, width: 7, height: 6)
    print("outputs \(outputs.map { Float($0 * 1) })")
}

demonstrateFutility()

func demonstrateQuixote() {
    
}
