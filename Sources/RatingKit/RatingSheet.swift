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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.height(260), .medium])
            .presentationDragIndicator(.visible)
        }
    }

    var title: String {
        switch step {
            case .rating: "Enjoying the experience?"
            case .feedback: "Help us improve"
        }
    }

    @ViewBuilder
    private var ratingView: some View {
        VStack {
            Text("Tap a star to rate it on the App Store.")
                .foregroundStyle(.secondary)
                .padding(.bottom)

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
        }
    }

    @ViewBuilder
    private var feedbackView: some View {
        VStack {
            Text("Tell us what we can do better.")
                .foregroundStyle(.secondary)
                .padding(.bottom)

            TextField("Feedback", text: $feedback, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .background(Color.white.opacity(0.3))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.8), lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.bottom, 8)

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
                Button(action: postRating) {
                    Text("Submit")
                        .padding(.vertical, 8)
                }
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
