#if os(iOS)
import Accelerate

/// The one transform the kit's spectral work uses: 1024 frames (about 23 ms
/// at 44.1 kHz), the first half of the magnitude spectrum.
enum Spectrum {
  static let size = 1024

  static func makeTransform() -> vDSP.DiscreteFourierTransform<Float>? {
    try? vDSP.DiscreteFourierTransform(
      previous: nil, count: size, direction: .forward, transformType: .complexComplex, ofType: Float.self)
  }

  /// The first half of the magnitude spectrum of the first `size` frames of
  /// `channel`, zero-padded when it is shorter; `nil` when it is empty.
  static func magnitudes(of channel: UnsafeBufferPointer<Float>, transform: vDSP.DiscreteFourierTransform<Float>) -> [Float]? {
    guard !channel.isEmpty else { return nil }
    var real = [Float](repeating: 0, count: size)
    for index in 0..<min(channel.count, size) {
      real[index] = channel[index]
    }
    let imaginary = [Float](repeating: 0, count: size)
    var outReal = [Float](repeating: 0, count: size)
    var outImaginary = [Float](repeating: 0, count: size)
    transform.transform(inputReal: real, inputImaginary: imaginary, outputReal: &outReal, outputImaginary: &outImaginary)
    return (0..<(size / 2)).map { hypot(outReal[$0], outImaginary[$0]) }
  }
}
#endif
