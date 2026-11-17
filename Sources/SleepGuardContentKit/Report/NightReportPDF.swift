import CoreGraphics
import Foundation
import SleepCore
import SwiftUI

/// A night's report as a PDF: the report's pages drawn in SwiftUI into a PDF
/// context, US Letter. Both apps share it; each shares the file its own way.
@MainActor
public enum NightReportPDF {
  /// `appName` goes in the title and the footer ("SleepGuard Sleep Report").
  public static func render(_ report: NightReport, appName: String) -> Data {
    let data = NSMutableData()
    var box = CGRect(origin: .zero, size: NightReportPage.size)
    guard let consumer = CGDataConsumer(data: data),
          let context = CGContext(consumer: consumer, mediaBox: &box, nil) else { return Data() }
    let capacity = NightReportPage.capacity(report)
    let pages = report.pages(firstPage: capacity.first, perPage: capacity.later)
    for (index, rows) in pages.enumerated() {
      let continued = pages.prefix(index).contains { !$0.isEmpty }
      let renderer = ImageRenderer(
        content: NightReportPage(report: report, appName: appName, index: index, rows: rows, continued: continued))
      renderer.proposedSize = ProposedViewSize(NightReportPage.size)
      renderer.render { _, draw in
        context.beginPDFPage(nil)
        draw(context)
        context.endPDFPage()
      }
    }
    context.closePDF()
    return data as Data
  }

  /// Writes the report to `directory` as "<prefix>-<date>.pdf" and returns its URL.
  public static func write(_ report: NightReport, appName: String, to directory: URL) throws -> URL {
    let url = directory.appendingPathComponent("\(appName)-\(fileDate(report.start)).pdf")
    try render(report, appName: appName).write(to: url, options: .atomic)
    return url
  }

  private static func fileDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }
}
