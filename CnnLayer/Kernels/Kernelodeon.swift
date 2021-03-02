// We are a way for the cosmos to know itself. -- C. Sagan

import Foundation
import MetalPerformanceShaders

class Kernelodeon {
    let cElements: Int
    let height: Int
    let width: Int

    var data: UnsafeMutableBufferPointer<Float>
    let deallocate: Bool

    let device: MTLDevice
    let image: MPSImage
    let region: MTLRegion

    deinit { if deallocate { data.deallocate() } }

    init(
        _ device: MTLDevice, _ width: Int, _ height: Int,
        data: UnsafeMutableBufferPointer<Float>? = nil
    ) {
        self.width = width
        self.height = height
        self.cElements = width * height

        self.device = device

        let d = MPSImageDescriptor(
            channelFormat: .float16,
            width: width, height: height, featureChannels: 1
        )

        self.image = MPSImage(device: device, imageDescriptor: d)
        self.region = MTLRegionMake2D(0, 0, width, height)

        if let d = data { self.data = d; self.deallocate = false; return }

        self.data = .allocate(capacity: cElements)
        self.data.initialize(repeating: 0)
        self.deallocate = true
    }

    init(
        _ device: MTLDevice, _ cElements: Int,
        data: UnsafeMutableBufferPointer<Float>?
    ) {
        self.width = cElements
        self.height = 1
        self.cElements = cElements

        self.device = device

        let d = MPSImageDescriptor(
            channelFormat: .float16,
            width: width, height: height, featureChannels: 1
        )

        self.image = MPSImage(device: device, imageDescriptor: d)
        self.region = MTLRegionMake2D(0, 0, width, height)

        if let d = data { self.data = d; self.deallocate = false; return }

        self.data = .allocate(capacity: cElements)
        self.data.initialize(repeating: 0)
        self.deallocate = true
    }

    func extractData(to outputBuffer: UnsafeMutableBufferPointer<FF32>) {
        let rr16 = UnsafeMutableRawPointer.allocate(
            byteCount: F16.bytes(FF16.self, outputBuffer.count),
            alignment: F16.alignment(FF16.self)
        )

        rr16.initializeMemory(as: FF16.self, repeating: 0, count: outputBuffer.count)

        image.texture.getBytes(
            rr16, bytesPerRow: F16.bytes(FF16.self, width),
            from: region, mipmapLevel: 0
        )

        let uu16 = rr16.bindMemory(to: FF16.self, capacity: outputBuffer.count)
        let ff16 = UnsafeBufferPointer(start: uu16, count: outputBuffer.count)
        F16.to32(from: ff16, result: outputBuffer)

        rr16.deallocate()
    }

    func inject(data: [FF32]) {
        data.withUnsafeBufferPointer { input32 in
            let ff16 =
                UnsafeMutableBufferPointer<FF16>.allocate(capacity: data.count)

            ff16.initialize(repeating: 0)

            F16.to16(from: input32, result: ff16)

            let rr16 = UnsafeRawPointer(ff16.baseAddress!)

            image.texture.replace(
                region: region, mipmapLevel: 0,
                withBytes: rr16, bytesPerRow: F16.bytes(FF16.self, width)
            )

            ff16.deallocate()
        }
    }
}
