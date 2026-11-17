import SleepCore
import SwiftUI

/// Name, birth year, sex, height, weight. The text is written back to the
/// profile on Return and when the page goes away, not on every keystroke.
struct ProfileIdentityPage: View {
  @Binding var profile: SleepProfile
  @State private var firstName: String
  @State private var birthYear: String
  @State private var height: String
  @State private var weight: String

  init(profile: Binding<SleepProfile>) {
    _profile = profile
    let value = profile.wrappedValue
    _firstName = State(initialValue: value.firstName ?? "")
    _birthYear = State(initialValue: value.birthYear.map(String.init) ?? "")
    _height = State(initialValue: value.heightCm.map { String(format: "%.0f", $0) } ?? "")
    _weight = State(initialValue: value.weightKg.map { String(format: "%.0f", $0) } ?? "")
  }

  var body: some View {
    ProfilePage(title: Strings.profileEditorStepYou) {
      ProfileTextField(title: Strings.profileFieldFirstName, text: $firstName)
      ProfileTextField(title: Strings.profileFieldBirthYear, text: $birthYear, number: true)
      ProfileChoice(title: Strings.profileFieldBiologicalSex, options: [
        (Strings.profileSexUnspecified, .unspecified),
        (Strings.profileSexFemale, .female),
        (Strings.profileSexMale, .male),
      ], selection: $profile.biologicalSex)
      ProfileTextField(title: Strings.profileFieldHeight, text: $height, number: true)
      ProfileTextField(title: Strings.profileFieldWeight, text: $weight, number: true)
    }
    .onSubmit(write)
    .onDisappear(perform: write)
  }

  private func write() {
    profile.firstName = firstName.isEmpty ? nil : firstName
    profile.birthYear = Int(birthYear)
    profile.heightCm = Double(height)
    profile.weightKg = Double(weight)
  }
}

/// Bedtime, hours of sleep, the main goal.
struct ProfileGoalsPage: View {
  @Binding var profile: SleepProfile
  @Environment(\.theme) private var theme

  var body: some View {
    ProfilePage(title: Strings.profileEditorStepGoals) {
      VStack(alignment: .leading, spacing: 8) {
        ProfileFieldTitle(text: Strings.profileFieldTargetBedtime)
        DatePicker(
          selection: Binding(get: { profile.targetBedtime ?? Self.defaultBedtime }, set: { profile.targetBedtime = $0 }),
          displayedComponents: .hourAndMinute) { Text(Strings.profileFieldTargetBedtime) }
          .labelsHidden()
        #if os(iOS)
          .datePickerStyle(.wheel)
        #endif
          .colorMultiply(theme.palette.accent)
          .frame(maxHeight: 120)
          .clipped()
      }
      VStack(alignment: .leading, spacing: 8) {
        ProfileFieldTitle(text: Strings.profileFieldTargetSleepHours)
        let hours = profile.targetSleepHours ?? SleepProfile.defaultSleepHours
        HStack {
          Slider(
            value: Binding(get: { hours }, set: { profile.targetSleepHours = $0 }),
            in: SleepProfile.sleepHoursRange, step: 0.5) { Text(Strings.profileFieldTargetSleepHours) }
            .tint(theme.palette.accent)
          Text(verbatim: String(format: "%.1fh", hours))
            .font(theme.typography.font(size: 17, weight: .semibold))
            .foregroundStyle(theme.palette.textPrimary)
            .frame(width: 60, alignment: .trailing)
        }
      }
      ProfileChoice(title: Strings.profileFieldPrimaryGoal, options: [
        (Strings.profileGoalSnoreLess, .snoreLess),
        (Strings.profileGoalSleepDeeper, .sleepDeeper),
        (Strings.profileGoalMoreConsistent, .moreConsistent),
        (Strings.profileGoalWakeRefreshed, .wakeRefreshed),
      ], selection: $profile.goal)
    }
  }

  /// 22:30 today, shown until a bedtime is chosen.
  private static var defaultBedtime: Date {
    Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date()
  }
}

/// Caffeine, alcohol, exercise, stress, screens before bed.
struct ProfileHabitsPage: View {
  @Binding var profile: SleepProfile

  var body: some View {
    ProfilePage(title: Strings.profileEditorStepHabits, spacing: 24) {
      ProfileChoice(title: Strings.profileFieldCaffeine, options: [
        (Strings.profileHabitCaffeineNone, .none),
        (Strings.profileHabitCaffeineLight, .light),
        (Strings.profileHabitCaffeineModerate, .moderate),
        (Strings.profileHabitCaffeineHeavy, .heavy),
      ], selection: $profile.caffeine)
      ProfileChoice(title: Strings.profileFieldAlcohol, options: [
        (Strings.profileHabitAlcoholNone, .none),
        (Strings.profileHabitAlcoholOccasional, .occasional),
        (Strings.profileHabitAlcoholRegular, .regular),
      ], selection: $profile.alcohol)
      ProfileChoice(title: Strings.profileFieldExercise, options: [
        (Strings.profileFrequencyRarely, .rarely),
        (Strings.profileFrequencySometimes, .sometimes),
        (Strings.profileFrequencyOften, .often),
      ], selection: $profile.exercise)
      ProfileChoice(title: Strings.profileFieldStress, options: [
        (Strings.profileStressLow, .low),
        (Strings.profileStressMedium, .medium),
        (Strings.profileStressHigh, .high),
      ], selection: $profile.stress)
      ProfileChoice(title: Strings.profileFieldScreens, options: [
        (Strings.profileScreenRarely, .rarely),
        (Strings.profileScreenSometimes, .sometimes),
        (Strings.profileScreenOften, .often),
      ], selection: $profile.screensBeforeBed)
    }
  }
}

/// Hobbies (comma separated) and occupation.
struct ProfilePersonalPage: View {
  @Binding var profile: SleepProfile
  @State private var hobbies: String

  init(profile: Binding<SleepProfile>) {
    _profile = profile
    _hobbies = State(initialValue: profile.wrappedValue.hobbies.joined(separator: ", "))
  }

  var body: some View {
    ProfilePage(title: Strings.profileEditorStepPersonal, spacing: 24) {
      ProfileTextField(title: Strings.profileFieldHobbies, text: $hobbies)
      ProfileChoice(title: Strings.profileFieldOccupation, options: [
        (Strings.profileOccupationDesk, .desk),
        (Strings.profileOccupationActive, .active),
        (Strings.profileOccupationShift, .shift),
        (Strings.profileOccupationOther, .other),
      ], selection: $profile.occupation)
    }
    .onSubmit(write)
    .onDisappear(perform: write)
  }

  private func write() {
    profile.hobbies = SleepProfile.hobbies(from: hobbies)
  }
}
