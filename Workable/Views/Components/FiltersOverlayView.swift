import SwiftUI

struct FiltersOverlayView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAll = true
    @State private var savedCandidatesOnly = false
    @State private var jobFitLow: Int = 0
    @State private var jobFitHigh: Int = 100
    @State private var showLowPicker = false
    @State private var showHighPicker = false
    @State private var meetsAllMustHaves = false
    @State private var doesntMeetMustHaves = false
    @State private var qualifiedSelected = true
    @State private var disqualifiedSelected = false
    @State private var selectedDateFilter: String? = nil
    @State private var aiAssistedSelected = false
    @State private var excludeAiAssistedSelected = false
    
    let resultsCount: Int
    /// Job row subtitle, e.g. `Title · details` from the candidates browser.
    let jobSummary: String

    init(resultsCount: Int, jobSummary: String = "Software Engineer · Engineering · Hybrid · Amsterdam / London / Prag...") {
        self.resultsCount = resultsCount
        self.jobSummary = jobSummary
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                filterNavBar
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        showCandidatesRow
                        divider
                        pickerRow(title: "Department", subtitle: "Any")
                        pickerRow(title: "Job", subtitle: jobSummary)
                        pickerRow(title: "Pipeline stage", subtitle: "Any")
                        savedCandidatesRow
                        jobFitSection
                        considerationStatusSection
                        tagsSection
                        candidateLocationSection
                        pickerRow(title: "Evaluation", subtitle: "Any")
                        applicationTypeSection
                        creationDateSection
                    }
                    .padding(.bottom, 100)
                }
            }
            .background(AppColors.surface)
            
            showResultsButton
        }
    }
    
    // MARK: - Nav Bar
    
    private var filterNavBar: some View {
        HStack {
            Button { dismiss() } label: {
                Text("Cancel")
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.primaryDark)
            }
            
            Spacer()
            
            Text("Filters")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.fontDefault)
            
            Spacer()
            
            Button { clearAll() } label: {
                Text("Clear all")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.primaryDark)
            }
        }
        .padding(16)
        .padding(.top, 16)
        .background(AppColors.surface)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.separator),
            alignment: .bottom
        )
    }
    
    // MARK: - Show candidates row
    
    private var showCandidatesRow: some View {
        HStack(spacing: 8) {
            Text("Show")
                .font(AppFonts.subheadStrong())
                .foregroundColor(AppColors.fontSecondary)
            
            Menu {
                Button("All") { showAll = true }
                Button("New") { showAll = false }
            } label: {
                HStack(spacing: 8) {
                    Text(showAll ? "All" : "New")
                        .font(AppFonts.subheadStrong())
                        .foregroundColor(AppColors.primaryDark)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.primaryDark)
                }
                .padding(12)
                .background(AppColors.background)
                .cornerRadius(8)
            }
            
            Text("candidates")
                .font(AppFonts.subheadStrong())
                .foregroundColor(AppColors.fontSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    // MARK: - Picker rows
    
    private func pickerRow(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.fontDefault)
                Text(subtitle)
                    .font(AppFonts.footnote())
                    .foregroundColor(AppColors.fontSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            
            divider
        }
    }
    
    // MARK: - Saved candidates toggle
    
    private var savedCandidatesRow: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.fontSecondary)
                    Text("Saved candidates only")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.fontDefault)
                }
                
                Spacer()
                
                Toggle("", isOn: $savedCandidatesOnly)
                    .labelsHidden()
                    .tint(AppColors.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            
            divider
        }
    }
    
    // MARK: - Job fit
    
    private var jobFitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Job fit")
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontDefault)
            
            VStack(spacing: 16) {
                HStack {
                    Button { showLowPicker = true } label: {
                        Text("\(jobFitLow)%")
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.fontSecondary)
                            .padding(10)
                            .background(AppColors.background)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showLowPicker) {
                        PercentageWheelPopover(selection: $jobFitLow) {
                            if jobFitLow > jobFitHigh { jobFitHigh = jobFitLow }
                        }
                    }
                    
                    Spacer()
                    
                    Button { showHighPicker = true } label: {
                        Text("\(jobFitHigh)%")
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.fontSecondary)
                            .padding(10)
                            .background(AppColors.background)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showHighPicker) {
                        PercentageWheelPopover(selection: $jobFitHigh) {
                            if jobFitHigh < jobFitLow { jobFitLow = jobFitHigh }
                        }
                    }
                }
                .padding(.trailing, 16)
                
                RangeSliderView(
                    low: Binding(get: { Double(jobFitLow) }, set: { jobFitLow = Int($0) }),
                    high: Binding(get: { Double(jobFitHigh) }, set: { jobFitHigh = Int($0) })
                )
                .padding(.trailing, 16)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        SelectionChip(
                            label: "Meets all must-haves",
                            isSelected: Binding(
                                get: { meetsAllMustHaves },
                                set: { newValue in
                                    meetsAllMustHaves = newValue
                                    if newValue { doesntMeetMustHaves = false }
                                }
                            ),
                            icon: "checkmark.circle.fill",
                            activeBackground: AppColors.activeBackground,
                            activeTextColor: AppColors.primaryDark
                        )
                        SelectionChip(
                            label: "Doesn't meet must-haves",
                            isSelected: Binding(
                                get: { doesntMeetMustHaves },
                                set: { newValue in
                                    doesntMeetMustHaves = newValue
                                    if newValue { meetsAllMustHaves = false }
                                }
                            ),
                            icon: "checkmark.circle.fill",
                            activeBackground: AppColors.activeBackground,
                            activeTextColor: AppColors.primaryDark
                        )
                    }
                }
            }
            
            divider
        }
        .padding(.leading, 16)
        .padding(.top, 16)
    }
    
    // MARK: - Consideration status
    
    private var considerationStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consideration status")
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontDefault)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    SelectionChip(
                        label: "Qualified",
                        isSelected: $qualifiedSelected,
                        icon: "checkmark.circle.fill",
                        activeBackground: AppColors.activeBackground,
                        activeTextColor: AppColors.primaryDark
                    )
                    SelectionChip(
                        label: "Disqualified",
                        isSelected: $disqualifiedSelected,
                        icon: "checkmark.circle.fill",
                        activeBackground: AppColors.activeBackground,
                        activeTextColor: AppColors.primaryDark
                    )
                }
            }
            
            divider
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - Tags
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontDefault)
            
            HStack(spacing: 8) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.fontSecondary)
                Text("Add a tag")
                    .font(AppFonts.callout())
                    .foregroundColor(AppColors.fontSecondary)
                Spacer()
            }
            .padding(10)
            .background(AppColors.background)
            .cornerRadius(8)
            
            divider
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - Candidate location
    
    private var candidateLocationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Candidate location")
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontDefault)
            
            HStack(spacing: 8) {
                Image(systemName: "mappin")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.fontSecondary)
                Text("Add a location")
                    .font(AppFonts.callout())
                    .foregroundColor(AppColors.fontSecondary)
                Spacer()
            }
            .padding(10)
            .background(AppColors.background)
            .cornerRadius(8)
            
            divider
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - Application type
    
    private var applicationTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Application type")
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontDefault)
            
            HStack(spacing: 8) {
                SelectionChip(
                    label: "AI-assisted",
                    isSelected: Binding(
                        get: { aiAssistedSelected },
                        set: { newValue in
                            aiAssistedSelected = newValue
                            if newValue { excludeAiAssistedSelected = false }
                        }
                    ),
                    icon: "checkmark.circle.fill",
                    activeBackground: AppColors.activeBackground,
                    activeTextColor: AppColors.primaryDark
                )
                SelectionChip(
                    label: "Exclude AI-assisted",
                    isSelected: Binding(
                        get: { excludeAiAssistedSelected },
                        set: { newValue in
                            excludeAiAssistedSelected = newValue
                            if newValue { aiAssistedSelected = false }
                        }
                    ),
                    icon: "checkmark.circle.fill",
                    activeBackground: AppColors.activeBackground,
                    activeTextColor: AppColors.primaryDark
                )
            }
            
            divider
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - Creation date
    
    private var creationDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Creation date")
                .font(AppFonts.body())
                .foregroundColor(AppColors.fontDefault)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["Custom dates", "This month", "Last 3 months", "Last year"], id: \.self) { option in
                        let isSelected = selectedDateFilter == option
                        Button {
                            selectedDateFilter = isSelected ? nil : option
                        } label: {
                            Text(option)
                                .font(AppFonts.subheadStrong())
                                .foregroundColor(isSelected ? AppColors.primaryDark : AppColors.fontSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(isSelected ? AppColors.activeBackground : AppColors.background)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    // MARK: - Show results button
    
    private var showResultsButton: some View {
        VStack {
            Button {
                dismiss()
            } label: {
                Text("Show \(resultsCount) results")
                    .font(AppFonts.headline())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(AppColors.primaryDark)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(
            LinearGradient(
                colors: [.white, .white.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
        )
    }
    
    // MARK: - Helpers
    
    private var divider: some View {
        Rectangle()
            .fill(AppColors.separator)
            .frame(height: 1)
    }
    
    private func clearAll() {
        showAll = true
        savedCandidatesOnly = false
        jobFitLow = 0
        jobFitHigh = 100
        meetsAllMustHaves = false
        doesntMeetMustHaves = false
        qualifiedSelected = false
        disqualifiedSelected = false
        selectedDateFilter = nil
        aiAssistedSelected = false
        excludeAiAssistedSelected = false
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    @Binding var isSelected: Bool
    
    var body: some View {
        Button { isSelected.toggle() } label: {
            Text(label)
                .font(AppFonts.subheadStrong())
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundColor(isSelected ? AppColors.primaryDark : AppColors.fontSecondary)
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(isSelected ? AppColors.activeBackground : AppColors.background)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Selection Chip (with icon)

struct SelectionChip: View {
    let label: String
    @Binding var isSelected: Bool
    let icon: String
    let activeBackground: Color
    let activeTextColor: Color
    
    var body: some View {
        Button { withAnimation(.easeInOut(duration: 0.15)) { isSelected.toggle() } } label: {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(activeTextColor)
                        .transition(.scale.combined(with: .opacity))
                }
                Text(label)
                    .font(AppFonts.subheadStrong())
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundColor(isSelected ? activeTextColor : AppColors.fontSecondary)
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(isSelected ? activeBackground : AppColors.background)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Range Slider

struct RangeSliderView: View {
    @Binding var low: Double
    @Binding var high: Double
    
    private let trackHeight: CGFloat = 6
    private let knobSize: CGFloat = 28
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width - knobSize
            let lowX = width * low / 100
            let highX = width * high / 100
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.separator)
                    .frame(height: trackHeight)
                
                Capsule()
                    .fill(AppColors.primaryDark)
                    .frame(
                        width: max(0, highX - lowX + knobSize),
                        height: trackHeight
                    )
                    .offset(x: lowX)
                
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                    .shadow(color: .black.opacity(0.12), radius: 13, x: 0, y: 6)
                    .frame(width: knobSize, height: knobSize)
                    .offset(x: lowX)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let raw: CGFloat = value.location.x / width * 100
                                low = Double(max(0, min(CGFloat(high) - 1, raw)))
                            }
                    )
                
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                    .shadow(color: .black.opacity(0.12), radius: 13, x: 0, y: 6)
                    .frame(width: knobSize, height: knobSize)
                    .offset(x: highX)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let raw: CGFloat = value.location.x / width * 100
                                high = Double(max(CGFloat(low) + 1, min(100, raw)))
                            }
                    )
            }
            .frame(height: knobSize)
        }
        .frame(height: 28)
    }
}

// MARK: - Percentage Typing Popover

private struct PercentageWheelPopover: View {
    @Binding var selection: Int
    var onChanged: () -> Void = {}

    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 4) {
            TextField("0–100", text: $inputText)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .font(AppFonts.headline())
                .foregroundColor(AppColors.fontDefault)
                .multilineTextAlignment(.center)
                .frame(width: 60)
                .onChange(of: inputText) { newValue in
                    let digits = newValue.filter(\.isNumber)
                    if let num = Int(digits) {
                        let clamped = min(100, max(0, num))
                        inputText = "\(clamped)"
                        selection = clamped
                        onChanged()
                    } else {
                        inputText = digits
                    }
                }

            Text("%")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.fontSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .presentationCompactAdaptation(.popover)
        .onAppear {
            inputText = "\(selection)"
            isFocused = true
        }
    }
}

#Preview {
    FiltersOverlayView(resultsCount: 136)
}
