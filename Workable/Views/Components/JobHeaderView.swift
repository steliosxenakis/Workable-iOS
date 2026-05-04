import SwiftUI

struct JobHeaderView: View {
    let title: String
    let subtitle: String
    let onTap: (() -> Void)?
    
    init(title: String, subtitle: String, onTap: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.onTap = onTap
    }
    
    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) {
                    headerLabel
                }
                .buttonStyle(.plain)
            } else {
                headerLabel
            }
        }
    }

    private var headerLabel: some View {
        VStack(alignment: .leading, spacing: 4) {
            // iOS/Headline — Semibold 17px, Oxford Blue #333E49
            Text(title)
                .font(AppFonts.headline())
                .foregroundColor(AppColors.oxfordBlue)

            HStack(alignment: .center, spacing: 8) {
                Text(subtitle)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.fontSecondary)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
