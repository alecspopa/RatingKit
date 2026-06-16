import SwiftUI

public extension View {
    func appFeedbackSheet(isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) { RatingSheet() }
    }
}
