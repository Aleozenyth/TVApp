import Foundation

/// Generic representation of the 3 required UI states: loading, error (with retry),
/// success. Kept generic over `Value` so both List (`[Show]`) and Detail (`Show`)
/// screens reuse the same state machine and the same switch-based view logic.
public enum ViewState<Value: Equatable>: Equatable {
    case idle
    case loading
    case success(Value)
    case failure(String)
}
