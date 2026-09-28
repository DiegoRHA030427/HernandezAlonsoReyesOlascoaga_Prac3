import SwiftUI

struct FileRowView: View {
    let item: FileSystemItem
    let isFavorite: Bool

    var body: some View {
        HStack(spacing: 12) {
            thumbnailOrIcon
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(item.name)
                        .font(.body)
                        .lineLimit(1)
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
                Text(item.isDirectory ? "Carpeta" : "\(item.formattedSize) · \(item.formattedDate)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if item.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var thumbnailOrIcon: some View {
        if let thumbnail = ThumbnailCache.shared.thumbnail(for: item) {
            Image(uiImage: thumbnail)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            Image(systemName: item.systemImageName)
                .font(.title2)
                .foregroundStyle(item.isDirectory ? Color.accentColor : Color.secondary)
                .frame(width: 36, height: 36)
        }
    }
}
