import Foundation

/// A clip's waveform: its audio averaged into `pointCount` bars, scaled so the
/// loudest is 1. Feed it the samples in order (each app reads the file its own
/// way); the rule is SleepGuard's `WaveformGenerator`.
public struct WaveformAccumulator: Sendable {
  public let pointCount: Int
  private let maxFrames: Int
  private let framesPerPoint: Int
  private var points: [Float]
  private var pointIndex = 0
  private var sum: Float = 0
  private var framesInPoint = 0
  private var framesSeen = 0

  /// `frames`: how many frames the clip has, or how many to use (a clip may
  /// hold trailing silence past its event).
  public init(frames: Int, pointCount: Int = 300) {
    self.pointCount = pointCount
    maxFrames = max(0, frames)
    framesPerPoint = max(1, maxFrames / max(1, pointCount))
    points = [Float](repeating: 0, count: pointCount)
  }

  /// No more frames are taken.
  public var isFull: Bool {
    framesSeen >= maxFrames
  }

  /// Adds the next samples (one channel).
  public mutating func add(_ samples: some Sequence<Float>) {
    for sample in samples {
      guard framesSeen < maxFrames else { return }
      sum += abs(sample)
      framesInPoint += 1
      framesSeen += 1
      if framesInPoint >= framesPerPoint {
        if pointIndex < pointCount {
          points[pointIndex] = sum / Float(framesInPoint)
          pointIndex += 1
        }
        sum = 0
        framesInPoint = 0
      }
    }
  }

  /// The bars, 0...1; all zero for silence or no frames.
  public var waveform: [Float] {
    guard maxFrames > 0, let loudest = points.max(), loudest > 1e-10 else { return points.map { _ in 0 } }
    return points.map { $0 / loudest }
  }
}
