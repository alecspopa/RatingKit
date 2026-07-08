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
                    .padding(.bottom)

                switch step {
                    case .rating: ratingView
                    case .feedback: feedbackView
                }

                Spacer()
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
                        withAnimation(.snappy) {
                            rating = idx

                            if let rating, rating >= ratingCutOff {
                                dismiss()
                                postRating()
                                requestReview()
                            } else {
                                step = .feedback
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
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue, lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.bottom, 8)


            Label("Tell us what we can improve.", systemImage: "info.circle")
                .font(.caption)

            if #available(iOS 26.0, *) {
                Button(action: postRating) {
                    Text("Submit")
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .buttonSizing(.flexible)
                .padding(.top)
                .padding(.horizontal)
                .disabled(rating == nil)
            } else {
                Button("Submit", action: postRating)
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                    .padding(.horizontal)
                    .disabled(rating == nil)
            }
        }
    }

    private func postRating() {
        if let rating {
            Task {
                try await RatingKit.shared.client.postRating(rating: .init(rating: rating, feedback: feedback))
            }

            dismiss()
        }
    }
}

#Preview {
    @Previewable @State var isPresented: Bool = true

    VStack {
        Text("Background")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.gray)
            .sheet(isPresented: $isPresented) {
                RatingSheet()
            }
    }
}
