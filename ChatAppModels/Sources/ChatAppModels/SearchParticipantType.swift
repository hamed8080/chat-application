public enum SearchParticipantType: String, CaseIterable, Identifiable {
    public var id: Self { self }
    case name = "Name"
    case username = "User Name"
    case cellphoneNumber = "Mobile"
    case admin = "Admin"
}
