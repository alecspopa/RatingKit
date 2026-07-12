import SwiftUI

public extension View {
    func appReviewSheet(isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) { ReviewSheet() }
    }
}
