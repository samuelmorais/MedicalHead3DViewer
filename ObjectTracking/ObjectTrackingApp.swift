/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's entry point.
*/

import SwiftUI

private enum UIIdentifier {
    static let immersiveSpace = "Object tracking"
}

@main
@MainActor
struct MedicalHead3DViewerApp: App {
    @State private var appState = AppState()
    @State private var showSkull: Bool = false
    @State private var showAxialBrain: Bool = false
    @State private var showCoronalBrain: Bool = false
    @State private var showArteries: Bool = false
    @State private var showInternalArteries: Bool = false
    @State private var showFace: Bool = false
    @State private var axialSlice: Float = 0
    @State private var coronalSlice: Float = 0
    @State private var axialSliceReverse: Float = 12
    @State private var coronalSliceReverse: Float = 11
    @State private var shouldTriggerAnimation: Bool = false
    var body: some Scene {
        WindowGroup {
            HomeView(
                appState: appState,
                immersiveSpaceIdentifier: UIIdentifier.immersiveSpace,
                showSkull: $showSkull,
                showAxialBrain: $showAxialBrain,
                showCoronalBrain: $showCoronalBrain,
                showArteries: $showArteries,
                showInternalArteries: $showInternalArteries,
                showFace: $showFace,
                coronalSlice: $coronalSlice,
                axialSlice: $axialSlice,
                coronalSliceReverse: $coronalSliceReverse,
                axialSliceReverse: $axialSliceReverse,
                shouldTriggerAnimation: $shouldTriggerAnimation
            )
            .task {
                if appState.allRequiredProvidersAreSupported {
                    await appState.referenceObjectLoader.loadBuiltInReferenceObjects()
                }
            }
        }
        .windowStyle(.plain)

        ImmersiveSpace(id: UIIdentifier.immersiveSpace) {
            ObjectTrackingRealityView(appState: appState,
                                      showSkull: $showSkull,
                                      showAxialBrain: $showAxialBrain,
                                      showCoronalBrain: $showCoronalBrain,
                                      showArteries: $showArteries,
                                      showInternalArteries: $showInternalArteries,
                                      showFace: $showFace,
                                      coronalSlice: $coronalSlice,
                                      axialSlice: $axialSlice,
                                      coronalSliceReverse: $coronalSliceReverse,
                                      axialSliceReverse: $axialSliceReverse,
                                      shouldTriggerAnimation: $shouldTriggerAnimation)
        }
    }
}
