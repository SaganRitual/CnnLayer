// We are a way for the cosmos to know itself. -- C. Sagan

import Foundation
import MetalPerformanceShaders

struct HotMess {

    func setupDataSource(width: Int, height: Int, weights: SwiftPointer<Float>) -> DataSourceCnn {
        let convolutionDescriptor = MPSCNNConvolutionDescriptor(
            kernelWidth: width, kernelHeight: height,
            inputFeatureChannels: 1, outputFeatureChannels: 1, neuronFilter: nil
        )

        convolutionDescriptor.strideInPixelsX = 1
        convolutionDescriptor.strideInPixelsY = 1

        return DataSourceCnn(
            biases: nil, weights: weights.raw, convolutionDescriptor: convolutionDescriptor
        )
    }

    func setupSourceImage(device: MTLDevice, width: Int, height: Int) -> MPSImage {
        let sourceImageDescriptor = MPSImageDescriptor(
            channelFormat: .float16, width: width, height: height, featureChannels: 1
        )

        let image = MPSImage(device: device, imageDescriptor: sourceImageDescriptor)

        return image
    }

    func setupDestinationImage(device: MTLDevice, width: Int, height: Int) -> MPSImage {

        let destinationImageDescriptor = MPSImageDescriptor(
            channelFormat: .float16, width: width, height: height, featureChannels: 1
        )

        let destinationImage = MPSImage(device: device, imageDescriptor: destinationImageDescriptor)
        destinationImageDescriptor.usage = .shaderWrite

        return destinationImage
    }

    func setupConvolution(device: MTLDevice, width: Int, height: Int, dataSource: DataSourceCnn) -> MPSCNNConvolution {
        let convolution = MPSCNNConvolution(device: device, weights: dataSource)

        convolution.offset = MPSOffset(x: width / 2, y: height / 2, z: 0)
        convolution.edgeMode = .zero

        return convolution
    }

    func setupInputs(
        _ inputs: [Float], inputImage: MPSImage, region: MTLRegion, elementsPerRow: Int
    ) {
        let inputs16 = float32sToFloat16s(inputs)

        inputImage.texture.replace(
            region: region, mipmapLevel: 0, withBytes: inputs16, bytesPerRow: elementsPerRow * MemoryLayout<UInt16>.size
        )
    }

    func getOutputs(from image: MPSImage, region: MTLRegion, width: Int, height: Int) -> [Float] {
        let outputs16___ = UnsafeMutableBufferPointer<FF16>.allocate(capacity: width * height)
        let outputs16__ = UnsafeBufferPointer(outputs16___)
        let outputs16_ = UnsafeMutableRawPointer(mutating: outputs16__.baseAddress!)

        image.texture.getBytes(outputs16_, bytesPerRow: width * MemoryLayout<UInt16>.size, from: region, mipmapLevel: 0)

        let outputs16 = outputs16___.map { $0 }

        defer { outputs16___.deallocate() }

        return float16sToFloat32s(outputs16)
    }
}
