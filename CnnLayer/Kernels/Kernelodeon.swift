// We are a way for the cosmos to know itself. -- C. Sagan

import Foundation
import MetalPerformanceShaders

class Kernelodeon {
    let cElements: Int
    let height: Int
    let width: Int

    let device: MTLDevice
    let image: MPSImage
    let region: MTLRegion

    init(_ device: MTLDevice, _ width: Int, _ height: Int) {
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
    }

    init(_ device: MTLDevice, _ cElements: Int) {
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
    }

    func extractData(to outputBuffer: UnsafeMutableBufferPointer<FF32>) {
        assert(outputBuffer.count == cElements)

        let bytesPerRow: Int = F16.bytesFF16(width)

        let ff16 = UnsafeMutableBufferPointer<FF16>.allocate(capacity: cElements)

        image.texture.getBytes(
            UnsafeMutableRawPointer(ff16.baseAddress!),
            bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0
        )

        F16.to32(from: UnsafeBufferPointer(ff16), result: outputBuffer)

        ff16.deallocate()
    }

    func inject(data: [FF32]) {
        data.withUnsafeBufferPointer { input32 in
            assert(data.count == cElements)

            let bytesPerRow: Int = F16.bytesFF16(width)

            let ff16 =
                UnsafeMutableBufferPointer<FF16>.allocate(capacity: cElements)

            ff16.initialize(repeating: 0)

            F16.to16(from: input32, result: ff16)

            let rr16 = UnsafeRawPointer(ff16.baseAddress!)

            image.texture.replace(
                region: region, mipmapLevel: 0,
                withBytes: rr16, bytesPerRow: bytesPerRow
            )

            ff16.deallocate()
        }
    }
}
