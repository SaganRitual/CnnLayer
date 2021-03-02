// We are a way for the cosmos to know itself. -- C. Sagan

import Foundation
import MetalPerformanceShaders

func demonstrateConvolution(
    input: [FF32], width: Int, height: Int, result: inout [FF32]
) {
    let device = MTLCopyAllDevices()[0]
    let commandQueue = device.makeCommandQueue()!
    let commandBuffer = commandQueue.makeCommandBuffer()!

    let source = Kernelodeon(device, width, height)
    let destination = Kernelodeon(device, width, height)

    let weights = [FF32](repeating: 1, count: width * height * 2)

    let c = weights.withUnsafeBufferPointer {
        Convolutioner(device: device, width: width, height: height, weights: $0)
    }

    source.inject(data: input)

    c.encode(to: commandBuffer, source: source, destination: destination)

    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    result.withUnsafeMutableBufferPointer { destination.extractData(to: $0) }
}
