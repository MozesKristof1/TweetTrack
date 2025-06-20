import SwiftUI

struct TaxonomyCardView: View {
    let sound: BirdSoundItem
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            VStack(spacing: 0) {
                TaxonomyRow(title: "Order", value: sound.order ?? "Unknown")
                Divider()
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                TaxonomyRow(title: "Family", value: sound.family ?? "Unknown")
                Divider()
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                TaxonomyRow(title: "Genus", value: sound.genus ?? "Unknown")
                Divider()
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                TaxonomyRow(title: "Species", value: sound.scientificName ?? "Unknown")
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .padding()

            Spacer()
        }
        .navigationTitle("Taxonomy")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

struct TaxonomyRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}
