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
        VStack(alignment: .leading, spacing: 4) {
            // iOS/Headline — Semibold 17px, Oxford Blue #333E49
            Text(title)
                .font(AppFonts.headline())
                .foregroundColor(AppColors.oxfordBlue)
            
            HStack(spacing: 4) {
                // iOS/Subhead 15px, font-secondary
                Text(subtitle)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.fontSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer(minLength: 0)
                
                // Icon 16px Small-arrow-right
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.fontSecondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}
