import SwiftUI

struct ImportHeroLabel: View {
    let statusText: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.primary)

            Text("Import Document")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            Text("Files, Photos, or Google Drive")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
