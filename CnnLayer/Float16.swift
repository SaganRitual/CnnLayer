//
//    Float16.swift
//    ZKit
//
//    The MIT License (MIT)
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in
//    all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//    THE SOFTWARE.
//

import Foundation
import Accelerate

typealias FF16 = UInt16
typealias FF32 = Float

typealias IB16 = UnsafeBufferPointer<FF16>
typealias IB32 = UnsafeBufferPointer<FF32>

typealias MB16 = UnsafeMutableBufferPointer<FF16>
typealias MB32 = UnsafeMutableBufferPointer<FF32>

typealias IR = UnsafeRawPointer
typealias MR = UnsafeMutableRawPointer

class F16<T, U> {
    let input16: [FF16]?
    let output16: [FF16]?

    let input32: [FF32]?
    let output32: [FF32]?

    init(_ input16: FF16) {
        self.input32 = nil
        self.output16 = nil

        self.input16 = [input16]
        self.output32 = [0]
    }

    init(_ input16: [FF16]) {
        self.input32 = nil
        self.output16 = nil

        self.input16 = input16
        self.output32 = [FF32](repeating: 0, count: input16.count)
    }

    init(_ input32: FF32) {
        self.input16 = nil
        self.output32 = nil

        self.input32 = [input32]
        self.output16 = [0]
    }

    init(_ input32: [FF32]) {
        self.input16 = nil
        self.output32 = nil

        self.input32 = input32
        self.output16 = [FF16](repeating: 0, count: input32.count)
    }
}

func float16ToFloat32(_ f16in: FF16) -> FF32 {
    return F16<FF16, FF32>(f16in).toFloat32()
}

func float16sToFloat32s(_ f16in: [FF16]) -> [FF32] {
    return F16<FF16, FF32>(f16in).toFloat32Array()
}

func float32ToFloat16(_ f32in: FF32) -> FF16 {
    return F16<FF16, FF32>(f32in).toFloat16()
}

func float32sToFloat16s(_ f32in: [FF32]) -> [FF16] {
    return F16<FF16, FF32>(f32in).toFloat16Array()
}

extension F16 {
    func toFloat32() -> FF32 {
        guard let f16 = input16, let f32 = output32 else {
            preconditionFailure(
                "Error: f16 -> f32 requested but f16/f32 isn't set up"
            )
        }

        guard f16.count == 1, f32.count == 1 else {
            preconditionFailure(
                "Can't convert multi-element to single or single-element to multi"
            )
        }

        f16.withUnsafeBufferPointer { f16in in
            let b16in_ = vImage_Buffer(
                data: MR(mutating: f16in.baseAddress!),
                height: 1, width: 1, rowBytes: bytes(FF16.self, 1)
            )

            let b16in = [b16in_]

            f32.withUnsafeBufferPointer { f32out in
                let b32out_ = vImage_Buffer(
                    data: MR(mutating: f32out.baseAddress!),
                    height: 1, width: 1, rowBytes: bytes(FF32.self, 1)
                )

                let b32out = [b32out_]

                vImageConvert_Planar16FtoPlanarF(b16in, b32out, 0)
            }
        }

        return f32.first!
    }

    func toFloat16() -> FF16 {
        guard let f32 = input32, let f16 = output16 else {
            preconditionFailure(
                "Error: f32 -> f16 requested but f16/f32 isn't set up"
            )
        }

        guard f16.count == 1, f32.count == 1 else {
            preconditionFailure(
                "Can't convert multi-element to single or single-element to multi"
            )
        }

        f32.withUnsafeBufferPointer { f32in in
            let b32in_ = vImage_Buffer(
                data: MR(mutating: f32in.baseAddress!),
                height: 1, width: 1, rowBytes: bytes(FF32.self, 1)
            )

            let b32in = [b32in_]

            f16.withUnsafeBufferPointer { f16out in
                let b16out_ = vImage_Buffer(
                    data: MR(mutating: f16out.baseAddress!),
                    height: 1, width: 1, rowBytes: bytes(FF16.self, 1)
                )

                let b16out = [b16out_]

                vImageConvert_PlanarFtoPlanar16F(b32in, b16out, 0)
            }
        }

        return f16.first!
    }

    func toFloat32Array() -> [FF32] {
        guard let f16 = input16, let f32 = output32 else {
            preconditionFailure(
                "Error: [f16] -> [f32] requested but f16/f32 isn't set up"
            )
        }

        f16.withUnsafeBufferPointer { f16in in
            let b16in_ = vImage_Buffer(
                data: MR(mutating: f16in.baseAddress!),
                height: 1, width: vImagePixelCount(f16.count),
                rowBytes: bytes(FF16.self, f16.count)
            )

            let b16in = [b16in_]

            f32.withUnsafeBufferPointer { f32out in
                let b32out_ = vImage_Buffer(
                    data: MR(mutating: f32out.baseAddress!),
                    height: 1, width: vImagePixelCount(f16.count),
                    rowBytes: bytes(FF32.self, f16.count)
                )

                let b32out = [b32out_]

                vImageConvert_Planar16FtoPlanarF(b16in, b32out, 0)
            }
        }

        return f32
    }

    func toFloat16Array() -> [FF16] {
        guard let f32 = input32, let f16 = output16 else {
            preconditionFailure(
                "Error: [f32] -> [f16] requested but f16/f32 isn't set up"
            )
        }

        f32.withUnsafeBufferPointer { f32in in
            let b32in_ = vImage_Buffer(
                data: MR(mutating: f32in.baseAddress!),
                height: 1, width: vImagePixelCount(f32.count),
                rowBytes: bytes(FF32.self, f32.count)
            )

            let b32in = [b32in_]

            f16.withUnsafeBufferPointer { f16out in
                let b16out_ = vImage_Buffer(
                    data: MR(mutating: f16out.baseAddress!),
                    height: 1, width: vImagePixelCount(f32.count),
                    rowBytes: bytes(FF16.self, f32.count)
                )

                let b16out = [b16out_]

                vImageConvert_Planar16FtoPlanarF(b32in, b16out, 0)
            }
        }

        return f16
    }
}

private extension F16 {
    func bytes<T>(_ type: T, _ elements: Int) -> vImagePixelCount {
        vImagePixelCount(MemoryLayout<T>.size * elements)
    }

    func bytes<T>(_ type: T, _ elements: Int) -> Int {
        Int(MemoryLayout<T>.size * elements)
    }
}

