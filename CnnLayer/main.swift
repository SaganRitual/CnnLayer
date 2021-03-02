// We are a way for the cosmos to know itself. -- C. Sagan

import Foundation
import MetalPerformanceShaders

func show(data: [FF32], width: Int, height: Int, header: String) {
    print("\(header) \(width) x \(height):")

    for h in 0..<height {
        for w in 0..<width {
            let s = String(format: "%.1f", data[w + h * width])
            let p = "     ".prefix(5 - s.count)
            print(p + s, terminator: "")
        }

        print()
    }
}

func main() {
    for width in 1...10 {
        for height in 1...10 {
            let input = [FF32](repeating: 1, count: width * height)
            var output = [FF32](repeating: 0, count: width * height)

            demonstrateConvolution(
                input: input, width: width, height: height, result: &output
            )

            show(data: input, width: width, height: height, header: "input")
            show(data: output, width: width, height: height, header: "output")
        }
    }
}

main()
