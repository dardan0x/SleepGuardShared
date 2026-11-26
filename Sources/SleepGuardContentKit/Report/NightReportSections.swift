import SleepCore
import SwiftUI
import SleepStrings

struct ReportHeader: View {
  let title: String
  let date: Date

  var body: some View {
    ZStack(alignment: .leading) {
      LinearGradient(colors: ReportPalette.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
      VStack(alignment: .leading, spacing: 10) {
        Text(title).font(.system(size: 32, weight: .bold)).foregroundStyle(.white)
        Text(date.formatted(date: .complete, time: .omitted))
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(.white.opacity(0.85))
      }
      .padding(.horizontal, NightReportPage.margin)
      Circle().fill(.white.opacity(0.15)).frame(width: 80, height: 80)
        .overlay(Circle().fill(.white.opacity(0.25)).frame(width: 48, height: 48))
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, 20)
    }
    .frame(height: 140)
  }
}

struct ReportScoreCard: View {
  let report: NightReport

  var body: some View {
    HStack(spacing: 32) {
      Text("\(report.score)")
        .font(.system(size: 36, weight: .bold))
        .foregroundStyle(ReportPalette.score(report.rating))
        .frame(width: 88, height: 88)
        .overlay(Circle().stroke(ReportPalette.score(report.rating), lineWidth: 6))
      VStack(alignment: .leading, spacing: 8) {
        Text(Strings.reportScoreLabel).font(.system(size: 12, weight: .semibold)).foregroundStyle(ReportPalette.textSecondary)
        Text(ReportText.rating(report.rating)).font(.system(size: 24, weight: .bold)).foregroundStyle(ReportPalette.textPrimary)
        Rectangle().fill(ReportPalette.divider).frame(height: 1)
        Text(report.stages == nil ? Strings.reportBasedOn : Strings.reportBasedOnStages)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(ReportPalette.textSecondary)
      }
    }
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
    .background(ReportPalette.card, in: .rect(cornerRadius: 20))
  }
}

struct ReportStatsGrid: View {
  let report: NightReport

  private var stats: [(String, String, String)] {
    var stats = [
      ("⏱", Strings.recordingsPlayerStatDuration, ReportText.duration(report.duration)),
      ("📊", Strings.sessionSummaryStatSnoring, ReportText.percent(report.snoringShare)),
      ("🔊", Strings.sessionSummaryStatSnoreTime, ReportText.duration(report.snoringDuration)),
      ("🔔", Strings.recordingsDetailEventsLabel, "\(report.eventCount)"),
    ]
    if let talking = report.sleepTalking { stats.append(("🗣", Strings.filterSleepTalking, "\(talking.count)")) }
    return stats
  }

  var body: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
      ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
        VStack(alignment: .leading, spacing: 4) {
          Text(verbatim: stat.0).font(.system(size: 20))
          Text(stat.1.uppercased()).font(.system(size: 11, weight: .semibold)).foregroundStyle(ReportPalette.textSecondary)
          Text(stat.2).font(.system(size: 22, weight: .bold)).foregroundStyle(ReportPalette.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .background(ReportPalette.card, in: .rect(cornerRadius: 16))
      }
    }
  }
}

struct ReportStages: View {
  let stats: StageStats

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(Strings.statisticsSleepStagesLabel).font(.system(size: 14, weight: .bold)).foregroundStyle(ReportPalette.textPrimary)
      ForEach([SleepStage.deep, .light, .rem, .awake], id: \.self) { stage in
        HStack {
          Circle().fill(ReportPalette.stage(stage)).frame(width: 10, height: 10)
          Text(stage.name).font(.system(size: 12, weight: .medium)).foregroundStyle(ReportPalette.textPrimary)
          Spacer()
          Text(ReportText.percent(stats.percent(of: stage))).font(.system(size: 12, weight: .semibold))
            .foregroundStyle(ReportPalette.textPrimary)
        }
      }
    }
    .padding(16)
    .background(ReportPalette.card, in: .rect(cornerRadius: 16))
  }
}

struct ReportSleepTalking: View {
  let talking: NightReport.SleepTalking

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(Strings.filterSleepTalking).font(.system(size: 14, weight: .bold)).foregroundStyle(ReportPalette.textPrimary)
      Text(String(format: Strings.reportSleepTalkingFormat, talking.count, ReportText.duration(talking.duration), ReportText.percent(talking.share)))
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(ReportPalette.textSecondary)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(ReportPalette.card, in: .rect(cornerRadius: 16))
  }
}

struct ReportEvents: View {
  let rows: [NightReport.Row]
  var continued = false

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(continued ? "\(Strings.reportEvents) · \(Strings.reportContinued)" : Strings.reportEvents)
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(ReportPalette.textPrimary)
      HStack(spacing: 0) {
        ForEach([Strings.reportColumnTime, Strings.reportColumnType, Strings.reportColumnDuration, Strings.reportColumnIntensity], id: \.self) {
          Text($0).font(.system(size: 11, weight: .semibold)).frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .foregroundStyle(ReportPalette.textPrimary)
      .padding(.leading, 34)
      .padding(.trailing, 10)
      Rectangle().fill(ReportPalette.divider).frame(height: 1)
      ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
        HStack(spacing: 0) {
          Circle().fill(ReportPalette.intensity(row.intensity)).frame(width: 10, height: 10).padding(.trailing, 14)
          Group {
            Text(row.start.formatted(date: .omitted, time: .shortened))
            Text(ReportText.kind(row.kind))
            Text(ReportText.duration(row.duration))
            Text(ReportText.intensity(row.intensity))
          }
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(ReportPalette.textPrimary)
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .frame(height: 36)
        .background(ReportPalette.row, in: .rect(cornerRadius: 8))
      }
    }
  }
}
