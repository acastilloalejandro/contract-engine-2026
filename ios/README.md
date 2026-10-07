# Contract Modular · iOS

Native SwiftUI application for creating, reviewing and preparing modular contractual dossiers.

## Product flow
Dashboard → New dossier → Parties → Modules A–E → Validation → Document preview → Verification QR → Signature reference → Export PDF.

## UX architecture
- SwiftUI with system typography, SF Symbols, standard controls and system materials.
- NavigationStack for hierarchical flows.
- NavigationSplitView for an adaptive iPhone/iPad experience. In compact layouts the split view collapses into a stack.
- Liquid Glass is intentionally limited to important custom actions. System navigation and controls are allowed to provide their native appearance.
- Adaptive LazyVGrid, Dynamic Type, safe-area aware layouts and system colors are used instead of fixed pixel coordinates.

## Technology
- Swift 6.2
- iOS/iPadOS 26.0+
- SwiftUI
- Foundation
- Observation
- PDFKit
- CryptoKit
- Core Image QR generation
- LocalAuthentication

## Open
Open ios/ContractModular.xcodeproj in Xcode 26 or later.

The app currently uses an in-memory demo store. Before production, connect AppStore to a real persistence layer such as SwiftData, add encrypted at-rest storage, authenticated verification endpoints and a qualified/eIDAS-compliant signature provider when legally required.

## Document model
A — Contractual loan
B — Guarantee
C — Professional-specialization permanence
D — NDA / confidentiality
E — Internal SLA / KPIs

The application is a document preparation and workflow tool. It does not certify legal validity and should not be presented as legal advice.

## Git workflow
This implementation is isolated in the branch feat/ios-contract-modular-app so the existing main branch remains unchanged.
