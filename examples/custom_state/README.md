# Custom State Example

This example demonstrates how to use **custom state payloads** with `flutter_reload` to handle business-level states in a type-safe and flexible way.

## Key Concepts

### Two-Layer State Design

`flutter_reload` separates concerns into two layers:

1. **System layer** (GuardState): Is the data loaded?
   - `InitGuardState` - Loading in progress
   - `NormalGuardState` - Loading completed successfully
   - `ErrorGuardState` - An unexpected error occurred
   - `OfflineGuardState` - Network connectivity issue

2. **Business layer** (payload): What is the outcome?
   - Custom states carried as generic payloads in `InitGuardState<T>` or `NormalGuardState<T>`

### Why Payload Instead of New State Types?

- **Simplicity**: No need to modify the library or create new state classes
- **Type-safety**: Use sealed classes for exhaustive pattern matching
- **Flexibility**: Each app defines its own business states
- **Separation**: System-level errors (offline, unexpected errors) are separate from business outcomes (subscription required, maintenance mode)

## Example Scenarios

This example simulates a content viewer that can result in different business outcomes:

| Scenario | State | Description |
|----------|-------|-------------|
| Content Ready | `NormalGuardState<ContentReady>` | Content loaded successfully |
| Subscription Required | `NormalGuardState<SubscriptionRequired>` | User needs to upgrade |
| Content Archived | `NormalGuardState<ContentArchived>` | Content is no longer available |
| Maintenance Mode | `NormalGuardState<MaintenanceMode>` | Service is under maintenance |

## Code Structure

```
lib/
├── states.dart   # Sealed class defining custom business states
├── model.dart    # ViewModel using custom payloads
├── view.dart     # UI handling all state cases
└── main.dart     # App configuration
```

## Running the Example

```bash
cd examples/custom_state
flutter pub get
flutter run
```

Tap the refresh button in the app bar to cycle through different scenarios.
