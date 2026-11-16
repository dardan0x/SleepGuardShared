// Screen content draws with the design kit and its strings: a screen that
// imports this product needs no second import for them.
@_exported import SleepGuardDesignKit

// Screen content (one screen's loaded layout) shared by the SleepGuard apps.
//
// A content view takes SleepCore values and action closures, and draws. It
// never loads, never navigates, never presents an alert or a sheet, and never
// draws a navigation bar: those belong to the screen that hosts it, in each
// app. An extra only one app shows goes through an optional value or a
// `@ViewBuilder` slot, never a flag naming an app.
