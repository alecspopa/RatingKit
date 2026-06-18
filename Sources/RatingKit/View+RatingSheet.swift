import SwiftUI

public extension View {
    func appRatingSheet(isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) { RatingSheet() }
    }
}
