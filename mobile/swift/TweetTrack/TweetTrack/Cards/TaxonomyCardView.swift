import SwiftUI

struct TaxonomyCardView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
                TaxonomyRow(title: "Order", value: "Passeriformes")
                TaxonomyRow(title: "Family", value: "Turdidae")
                TaxonomyRow(title: "Genus", value: "Turdus")
                TaxonomyRow(title: "Species", value: "Turdus merula")
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
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
            Text("\(title):")
                .fontWeight(.semibold)
            Spacer()
            Text(value)
        }
    }
}
