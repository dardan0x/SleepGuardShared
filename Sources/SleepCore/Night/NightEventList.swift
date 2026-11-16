import Foundation

/// Which events a night's event list shows.
public enum EventFilter: CaseIterable, Hashable, Sendable {
  case all
  case snoring
  case sleepTalking
  case noise

  public func includes(_ category: SoundCategory) -> Bool {
    switch self {
    case .all: true
    case .snoring: category == .snoring
    case .sleepTalking: category == .sleepTalking
    case .noise: category == .noise || category == .coughing || category == .other
    }
  }

  /// The filters to offer: every one, when the night has more than one kind
  /// of event (otherwise none, and no picker). Without sleep-talking
  /// detection, that filter and that kind don't count.
  public static func options(for events: [NightEvent], includeSleepTalking: Bool = true) -> [EventFilter] {
    let kinds = Set(events.compactMap { event -> EventFilter? in
      switch event.category {
      case .snoring: .snoring
      case .sleepTalking: includeSleepTalking ? .sleepTalking : nil
      case .noise, .coughing, .other: .noise
      }
    })
    guard kinds.count > 1 else { return [] }
    return allCases.filter { includeSleepTalking || $0 != .sleepTalking }
  }
}

/// One row of a night's event list.
public struct EventListRow: Identifiable, Equatable, Sendable {
  /// The event that plays first when the row is tapped: a snoring episode's
  /// representative (its longest event), or the event itself.
  public let id: UUID
  /// When it began: for snoring, the episode's start.
  public let start: Date
  /// For snoring, the episode's snoring time (gaps where snoring resumed
  /// included).
  public let duration: TimeInterval
  public let category: SoundCategory
  public let intensity: SnoreIntensity

  public init(id: UUID, start: Date, duration: TimeInterval, category: SoundCategory, intensity: SnoreIntensity) {
    self.id = id
    self.start = start
    self.duration = duration
    self.category = category
    self.intensity = intensity
  }

  /// The list both apps show: snoring as one row per displayable episode,
  /// every other event on its own, under `filter`, in time order.
  public static func rows(for night: Night, filter: EventFilter = .all) -> [EventListRow] {
    let snoring = night.displayableEpisodes.map { episode in
      EventListRow(
        id: episode.representativeEvent.id, start: episode.start, duration: episode.snoreDuration,
        category: .snoring, intensity: episode.intensity)
    }
    let others = night.events.filter { $0.category != .snoring }.map { event in
      EventListRow(id: event.id, start: event.start, duration: event.duration, category: event.category, intensity: event.intensity)
    }
    return (snoring + others).filter { filter.includes($0.category) }.sorted { $0.start < $1.start }
  }

  /// What tapping the row plays: a snoring row's whole episode in order,
  /// anything else alone.
  public func playback(in events: [NightEvent]) -> [NightEvent] {
    guard let event = events.first(where: { $0.id == id }) else { return [] }
    return SnoringEpisodes.playbackEvents(for: event, in: events)
  }
}
