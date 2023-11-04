public enum ThreadsSheetType: Identifiable {
    public var id: Self { self }
    case createConversation
    case showStartConversationBuilder
    case tagManagement
    case firstConfrimation
    case secondConfirmation
    case addParticipant
    case fastMessage
    case joinToPublicThread
}
