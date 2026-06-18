import SwiftUI

import StoreKit
import SwiftUI

struct RatingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) var requestReview

    private enum Step {
        case rating
        case feedback
    }

    @State private var step: Step = .rating
    @State private var rating: Int?
    @State private var feedback: String = ""
    private let ratingCutOff: Int = 3

    var body: some View {
        NavigationStack {
            VStack {
                Divider()
                Spacer()

                switch step {
                    case .rating: ratingView
                    case .feedback: feedbackView
                }

                Spacer()

                Button("Submit", action: sheetAction)
                    .buttonStyle(.glassProminent)
                    .buttonSizing(.flexible)
                    .padding()
            }
            .navigationTitle("Rate your experience")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.height(240), .medium])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var ratingView: some View {
        VStack {
            HStack {
                ForEach(1...5, id: \.self) { idx in
                    Button(action: {
                        if rating == nil {
                            withAnimation(.snappy) {
                                rating = idx
                            }
                        }
                    }) {
                        Image(systemName: idx <= (rating ?? 0) ? "star.fill" : "star")
                            .font(.largeTitle)
                    }
                }
            }
            .padding(.bottom)

            Label("Please rate the app so others can learn about it.", systemImage: "info.circle")
                .font(.caption)
        }
    }

    @ViewBuilder
    private var feedbackView: some View {
        VStack {
            TextField("Feedback", text: $feedback)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.bottom, 6)


            Label("Tell us what we can improve.", systemImage: "info.circle")
                .font(.caption)
        }
    }

    private func sheetAction() {
        if let rating, rating >= ratingCutOff {
            dismiss()
            requestReview()
        } else {
            if step == .rating {
                step = .feedback
            } else {
                // TODO: submit to backend
                dismiss()
            }
        }
    }
}

#Preview {
    @Previewable @State var isPresented: Bool = true
    @Previewable @State var rating: Int? = nil

    VStack {
        Text("Background")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.gray)
            .sheet(isPresented: $isPresented) {
                RatingSheet()
            }
    }
}
