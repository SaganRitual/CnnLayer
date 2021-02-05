// We are a way for the cosmos to know itself. -- C. Sagan

import Foundation
import MetalPerformanceShaders

struct HotMess {

    func setupDataSource(width: Int, height: Int, weights: SwiftPointer<Float>) -> DataSourceCnn {
        let convolutionDescriptor = MPSCNNConvolutionDescriptor(
            kernelWidth: width, kernelHeight: height,
            inputFeatureChannels: 1, outputFeatureChannels: 1, neuronFilter: nil
        )

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
        let inputs32 = SwiftPointer(Float.self, elements: inputs.count)
        inputs32.raw.initializeMemory(as: Float.self, from: inputs, count: inputs.count)

        let inputs16 = SwiftPointer(UInt16.self, elements: inputs.count)

        Float16.floats_to_float16s(input: inputs32.raw, output: inputs16.getMutableBufferPointer())

        inputImage.texture.replace(
            region: region, mipmapLevel: 0, withBytes: inputs16.getRawPointer(), bytesPerRow: elementsPerRow * MemoryLayout<UInt16>.size
        )
    }

    func getOutputs(from image: MPSImage, region: MTLRegion, width: Int, height: Int) -> [Float] {
        let outputs16 = SwiftPointer(UInt16.self, elements: width * height)

        image.texture.getBytes(outputs16.raw, bytesPerRow: width * MemoryLayout<UInt16>.size, from: region, mipmapLevel: 0)

        return Float16.float16s_to_floats(values: outputs16.getArray())
    }

}
