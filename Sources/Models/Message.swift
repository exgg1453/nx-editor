import Foundation

struct Message: Identifiable, Equatable {
    let id = UUID()
    let role: String
    var text: String
}
