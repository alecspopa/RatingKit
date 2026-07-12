import SwiftUI

import StoreKit
import SwiftUI

struct ReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) var requestReview

    private enum Step {
        case review
        case feedback
    }

    @State private var step: Step = .review
    @State private var feedback: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                Divider()
                    .padding(.bottom)

                Spacer()

                switch step {
                    case .review: reviewView
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
            case .review: "Enjoying the experience?"
            case .feedback: "Help us improve"
        }
    }

    @ViewBuilder
    private var reviewView: some View {
        VStack {
            Text("Your feedback is very important to us.")
                .foregroundStyle(.secondary)
                .padding(.bottom)

            HStack {
                Button(action: { step = .feedback }) {
                    Text("Not really")
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.top)
                .padding(.horizontal)

                Button(action: {
                    dismiss()
                    requestReview()
                }) {
                    Text("Yes")
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
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
                Button(action: postFeedback) {
                    Text("Send feedback")
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .buttonSizing(.flexible)
                .padding(.top)
                .padding(.horizontal)
            } else {
                Button(action: postFeedback) {
                    Text("Send feedback")
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
                .padding(.horizontal)
            }
        }
    }

    private func postFeedback() {
        Task {
            try await RatingKit.shared.client.postFeedback(feedback)
        }

        dismiss()
    }
}

#Preview {
    @Previewable @State var isPresented: Bool = true

    VStack {
        Button(action: { isPresented.toggle() }) {
            Text("Show sheet")
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.gray)
    .sheet(isPresented: $isPresented) {
        ReviewSheet()
    }
}
