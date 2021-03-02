// We are a way for the cosmos to know itself. -- C. Sagan

import Foundation
import MetalPerformanceShaders
/*
func demonstrateFutility() {
    let device = MTLCopyAllDevices()[0]

    let s1Data: [Float] = ([Int](0..<16)).map { _ in Float(Bool.random() ? 1 : 1) }
//    let s2Data: [Float] = ([Int](0..<16)).map { _ in Float(Bool.random() ? 1 : 1) }

    let s2Data: [Float] = [
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 1, 1
    ]

    let s1Region: MTLRegion; s1Region = MTLRegionMake2D(0, 0, 4, 4)
    let s2Region = MTLRegionMake2D(0, 0, 4, 4)
    let dRegion = MTLRegionMake2D(0, 0, 4, 4)

    let hotMess = HotMess()

    let s1Image = hotMess.setupSourceImage(device: device, width: 4, height: 4)
    let s2Image = hotMess.setupSourceImage(device: device, width: 4, height: 4)
    let dImage = hotMess.setupDestinationImage(device: device, width: 4, height: 4)

    hotMess.setupInputs(s1Data, inputImage: s1Image, region: s1Region, elementsPerRow: 4)
    hotMess.setupInputs(s2Data, inputImage: s2Image, region: s2Region, elementsPerRow: 4)

//    let weights = SwiftPointer(Float.self, elements: 42 * 30)
//    weights.getMutableBufferPointer().assign(repeating: 1)

//    let ds = hotMess.setupDataSource(width: 42, height: 30, weights: weights)
//    let fucerometer = MPSCNNFullyConnected(device: device, weights: ds)
//
//    fucerometer.clipRect.size.width = 4
//    fucerometer.clipRect.size.height = 4

//    let myWeights = SwiftPointer<Float>(Float.self, elements: 16)
////    myWeights.getMutableBufferPointer().initialize(repeating: 1)
//    _ = myWeights.getMutableBufferPointer().initialize(from:[
//        0, 0, 0, 0.25,
//        0, 0, 0, 1,
//        0, 0, 0, 1,
//        0, 0, 0, 1
//    ])

//    let dDataSource = hotMess.setupDataSource(width: 4, height: 4, weights: myWeights)
//    let convolometer = hotMess.setupConvolution(device: device, width: 4, height: 4, dataSource: ds)
    let multiplier = MPSCNNMultiply(device: device)

//    let poolerometer = MPSCNNPoolingMax(device: device, kernelWidth: 4, kernelHeight: 4)
//    poolerometer.offset.x = 1
//    poolerometer.offset.y = 1
//    poolerometer.edgeMode = .zero

    let commandQueue = device.makeCommandQueue()!
    let commandBuffer = commandQueue.makeCommandBuffer()!

//    poolerometer.encode(
//        commandBuffer: commandBuffer, sourceImage: source1Image,
//        destinationImage: destinationImage
//    )

//    convolometer.encode(commandBuffer: commandBuffer, sourceImage: source1Image, destinationImage: destinationImage)
    multiplier.encode(
        commandBuffer: commandBuffer,
        primaryImage: s1Image,
        secondaryImage: s2Image,
        destinationImage: dImage
    )

    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    print("s1Data", s1Data)
    print("s2Daa", s2Data)
    let outputs = hotMess.getOutputs(from: dImage, region: dRegion, width: 4, height: 4)
    print("outputs \(outputs.map { Float($0) })")
}

demonstrateFutility()
*/

func demonstrateQuixote(width: Int, height: Int) {
    let device = MTLCopyAllDevices()[0]
    let commandQueue = device.makeCommandQueue()!
    let commandBuffer = commandQueue.makeCommandBuffer()!

    let source = Kernelodeon(device, width, height)
    let destination = Kernelodeon(device, width, height)

    let weights = UnsafeMutableBufferPointer<Float>.allocate(
        capacity: width * height * 2
    )

    weights.initialize(repeating: 1)
    defer { weights.deallocate() }

    let c = Convolutioner(
        device: device, width: width, height: height,
        weights: UnsafeBufferPointer(rebasing: weights[...])
    )

    let yeOldeData = [FF32](repeating: 1, count: width * height)

    source.inject(data: yeOldeData)

    c.encode(to: commandBuffer, source: source, destination: destination)

    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    let rr32 = UnsafeMutableBufferPointer<FF32>.allocate(capacity: width * height)

    destination.extractData(to: rr32)

    print("input  \(yeOldeData)")
    print("result \(rr32.map { Float($0) /* 256.0 / 127.0*/ })")
}

demonstrateQuixote(width: 4, height: 4)
