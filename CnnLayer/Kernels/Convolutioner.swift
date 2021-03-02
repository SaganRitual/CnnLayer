// We are a way for the cosmos to know itself. -- C. Sagan

import Foundation
import MetalPerformanceShaders

class Convolutioner: NSObject {
    private let pBiases: UnsafeBufferPointer<Float>?
    private let pWeights: UnsafeBufferPointer<Float>

    private var convolution: MPSCNNConvolution!
    private var convolutionDescriptor: MPSCNNConvolutionDescriptor!

    private let weights_: UnsafeMutableRawPointer
    private let biases_: UnsafeMutablePointer<Float>?

    init(
        device: MTLDevice, width: Int, height: Int,
        weights: UnsafeBufferPointer<Float>,
        biases: UnsafeBufferPointer<Float>? = nil
    ) {
        self.pWeights = weights
        self.pBiases = biases

        self.weights_ = UnsafeMutableRawPointer(mutating: pWeights.baseAddress!)

        if let b = biases {
            biases_ = UnsafeMutablePointer(mutating: b.baseAddress!)
        } else { biases_ = nil }

        super.init()

        let d = MPSCNNConvolutionDescriptor(
            kernelWidth: width, kernelHeight: height,
            inputFeatureChannels: 1, outputFeatureChannels: 1, neuronFilter: nil
        )

        d.strideInPixelsX = 1
        d.strideInPixelsY = 1

        self.convolutionDescriptor = d
        self.convolution = MPSCNNConvolution(device: device, weights: self)

        convolution.offset = MPSOffset(x: width / 2, y: height / 2, z: 0)
        convolution.edgeMode = .zero
    }

    func encode(
        to cb: MTLCommandBuffer, source: Kernelodeon, destination: Kernelodeon
    ) {
        convolution.encode(
            commandBuffer: cb, sourceImage: source.image,
            destinationImage: destination.image
        )
    }
}

extension Convolutioner: MPSCNNConvolutionDataSource {
    func dataType() ->   MPSDataType { .float32 }
    func descriptor() -> MPSCNNConvolutionDescriptor { convolutionDescriptor }
    func weights() ->    UnsafeMutableRawPointer { weights_ }
    func biasTerms() ->  UnsafeMutablePointer<Float>? { biases_ }
    func load() -> Bool { true }
    func purge() { }
    func label() -> String? { nil }
    func copy(with zone: NSZone? = nil) -> Any { false }
}

