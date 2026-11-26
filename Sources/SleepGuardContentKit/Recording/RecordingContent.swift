import SleepCore
import SwiftUI
import SleepGuardDesignKit
import SleepStrings

/// Before a night: what to expect, two tips, the recording options, then Start
/// and Cancel pinned to the bottom. The screen checks the microphone and the
/// charger when Start is tapped. `options` sits under the tips (SleepGuard's
/// start delay and Snore Interrupter rows).
public struct PrestartContent<Options: View>: View {
  let compact: Bool
  let onStart: () -> Void
  let onCancel: () -> Void
  let options: Options
  @Environment(\.theme) private var theme

  /// `compact` for short screens (SleepGuard: height ≤ 874 pt).
  public init(compact: Bool, onStart: @escaping () -> Void, onCancel: @escaping () -> Void, @ViewBuilder options: () -> Options) {
    self.compact = compact
    self.onStart = onStart
    self.onCancel = onCancel
    self.options = options()
  }

  public var body: some View {
    ZStack(alignment: .bottom) {
      ScrollView {
        PrestartStack(compact: compact, options: options)
      }

      VStack(spacing: 0) {
        StartRecordingButton(height: 56, action: onStart)
        Button(action: onCancel) {
          Text(Strings.actionCancel)
            .font(theme.typography.font(size: 17, weight: .medium))
            .foregroundStyle(theme.palette.textSecondary)
        }
      }
      .padding(.horizontal, 24)
      .background(theme.palette.bgPrimary.ignoresSafeArea(edges: .bottom))
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
  }
}

/// The prestart's scrolling part: header, tips, options, room for the buttons.
struct PrestartStack<Options: View>: View {
  let compact: Bool
  let options: Options

  var body: some View {
    VStack(spacing: 0) {
      PrestartHeader(compact: compact)
        .padding(.top, compact ? 20 : 24)
      PrestartTipsCard()
        .padding(.top, compact ? 20 : 24)
      options
        .padding(.top, compact ? 20 : 24)
      Color.clear.frame(height: 160)
    }
    .padding(.horizontal, 24)
  }
}

public extension PrestartContent where Options == EmptyView {
  init(compact: Bool, onStart: @escaping () -> Void, onCancel: @escaping () -> Void) {
    self.init(compact: compact, onStart: onStart, onCancel: onCancel) { EmptyView() }
  }
}

/// The screen left on the nightstand: events so far, a dim clock, how long it
/// has recorded with a level meter, the snoring tier, and Stop. The screen
/// ticks `time` (once a second is enough) and decides what Stop does.
/// `banner` goes under the events badge, `overlay` over the top (SleepGuard's
/// melody disclaimer and melody controls).
public struct BedsideClockContent<Banner: View, Overlay: View>: View {
  let time: Date
  let elapsed: TimeInterval
  let eventCount: Int
  let db: Float
  let snoreState: DetectionState
  let canStop: Bool
  let onStop: () -> Void
  let banner: Banner
  let overlay: Overlay
  @Environment(\.theme) private var theme

  public init(
    time: Date,
    elapsed: TimeInterval,
    eventCount: Int,
    db: Float,
    snoreState: DetectionState,
    canStop: Bool = true,
    onStop: @escaping () -> Void,
    @ViewBuilder banner: () -> Banner,
    @ViewBuilder overlay: () -> Overlay)
  {
    self.time = time
    self.elapsed = elapsed
    self.eventCount = eventCount
    self.db = db
    self.snoreState = snoreState
    self.canStop = canStop
    self.onStop = onStop
    self.banner = banner()
    self.overlay = overlay()
  }

  public var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 8) {
        HStack {
          Spacer()
          BedsideEventsBadge(count: eventCount)
        }
        .padding(.top, 16)
        .padding(.horizontal, 24)
        banner
      }
      Spacer()
      BedsideClockFace(time: time)
      Spacer()
      BedsideRecordingStatus(elapsed: elapsed, db: db, time: time)
      Spacer()
      BedsideSnoreStatus(state: snoreState)
      Spacer()
      StopRecordingButton(height: 52, action: onStop)
        .disabled(!canStop)
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
    .overlay(alignment: .top) { overlay }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
  }
}

public extension BedsideClockContent where Banner == EmptyView, Overlay == EmptyView {
  init(
    time: Date,
    elapsed: TimeInterval,
    eventCount: Int,
    db: Float,
    snoreState: DetectionState,
    canStop: Bool = true,
    onStop: @escaping () -> Void)
  {
    self.init(
      time: time, elapsed: elapsed, eventCount: eventCount, db: db, snoreState: snoreState, canStop: canStop,
      onStop: onStop, banner: { EmptyView() }, overlay: { EmptyView() })
  }
}

/// The night just recorded: how long, its score, snoring share and events,
/// the banners that explain gaps, its timeline, then Save or Discard. The
/// screen decides what Save does (a night too short to keep).
public struct SessionSummaryContent: View {
  let night: Night
  let summary: NightSummary
  let onSave: () -> Void
  let onDiscard: () -> Void
  @Environment(\.theme) private var theme

  public init(night: Night, summary: NightSummary, onSave: @escaping () -> Void, onDiscard: @escaping () -> Void) {
    self.night = night
    self.summary = summary
    self.onSave = onSave
    self.onDiscard = onDiscard
  }

  public var body: some View {
    ScrollView {
      SessionSummaryStack(night: night, summary: summary, onSave: onSave, onDiscard: onDiscard)
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
  }
}

/// The summary's scrolling part.
struct SessionSummaryStack: View {
  let night: Night
  let summary: NightSummary
  let onSave: () -> Void
  let onDiscard: () -> Void

  var body: some View {
    VStack(spacing: 32) {
      SessionSummaryHeader(
        duration: night.duration, score: summary.score, snoringPercent: summary.snoringShare * 100,
        eventCount: summary.eventCount)
      if night.melodyGapsDuration > 0 {
        RecordingGapsBanner(totalGap: night.melodyGapsDuration)
      }
      if night.interruptionDuration > 0 {
        InterruptionGapsBanner(totalGap: night.interruptionDuration)
      }
      if night.endReason == .lowBattery {
        LowBatteryBanner()
      }
      NightTimeline(night: night, showsTitle: false)
      SessionSummaryActions(onSave: onSave, onDiscard: onDiscard)
    }
    .padding(24)
  }
}
