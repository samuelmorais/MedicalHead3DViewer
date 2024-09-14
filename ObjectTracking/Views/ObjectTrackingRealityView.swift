/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view shown inside the immersive space.
*/

import RealityKit
import ARKit
import SwiftUI

@MainActor
struct ObjectTrackingRealityView: View {
    var appState: AppState
    @Binding var showSkull: Bool
    @Binding var showAxialBrain: Bool
    @Binding var showCoronalBrain: Bool
    @Binding var showArteries: Bool
    @Binding var showInternalArteries: Bool
    @Binding var showFace: Bool
    @Binding var coronalSlice: Float
    @Binding var axialSlice: Float
    @Binding var coronalSliceReverse: Float
    @Binding var axialSliceReverse: Float
    @Binding var shouldTriggerAnimation: Bool
    var root = Entity()
    
    @State private var objectVisualizations: [UUID: ObjectAnchorVisualization] = [:]

    var body: some View {
        RealityView { content in
            content.add(root)
            
            Task {
                let objectTracking = await appState.startTracking()
                guard let objectTracking else {
                    return
                }
                
                // Wait for object anchor updates and maintain a dictionary of visualizations
                // that are attached to those anchors.
                for await anchorUpdate in objectTracking.anchorUpdates {
                    let anchor = anchorUpdate.anchor
                    let id = anchor.id
                    
                    switch anchorUpdate.event {
                    case .added:
                        // Create a new visualization for the reference object that ARKit just detected.
                        // The app displays the USDZ file that the reference object was trained on as
                        // a wireframe on top of the real-world object, if the .referenceobject file contains
                        // that USDZ file. If the original USDZ isn't available, the app displays a bounding box instead.
                        let model = appState.referenceObjectLoader.usdzsPerReferenceObjectID[anchor.referenceObject.id]
                        let visualization = await ObjectAnchorVisualization(for: anchor, withModel: model)
                        self.objectVisualizations[id] = visualization
                        root.addChild(visualization.entity)
                        objectVisualizations.values.forEach { visualization in
                            showSkull = false
                            showAxialBrain = false
                            showCoronalBrain = false
                            showArteries = false
                            showInternalArteries = false
                            showFace = true
                            visualization.hideAll()
                            
                        }
                    case .updated:
                        objectVisualizations[id]?.update(with: anchor)
                    case .removed:
                        objectVisualizations[id]?.entity.removeFromParent()
                        objectVisualizations.removeValue(forKey: id)
                    }
                }
            }
        }
        .onChange(of: showSkull) { isShowingSkull in
            if(isShowingSkull) {
                objectVisualizations.values.forEach { visualization in
                    visualization.showSkull()
                }
            }
            else {
                objectVisualizations.values.forEach { visualization in
                    visualization.hideSkull()
                }
            }
        }
        .onChange(of: showAxialBrain) { isShowingAxialBrain in
            if(isShowingAxialBrain) {
                objectVisualizations.values.forEach { visualization in
                    visualization.showBrainAxial()
                }
            }
            else {
                objectVisualizations.values.forEach { visualization in
                    visualization.hideBrainAxial()
                }
            }
        }
        .onChange(of: showCoronalBrain) { isShowingCoronalBrain in
            if(isShowingCoronalBrain) {
                objectVisualizations.values.forEach { visualization in
                    visualization.showBrainCoronal()
                }
            }
            else {
                objectVisualizations.values.forEach { visualization in
                    visualization.hideBrainCoronal()
                }
            }
        }
        .onChange(of: showArteries) { isShowingArteries in
            if(isShowingArteries) {
                objectVisualizations.values.forEach { visualization in
                    visualization.showArteries()
                }
            }
            else {
                objectVisualizations.values.forEach { visualization in
                    visualization.hideArteries()
                }
            }
        }
        .onChange(of: showInternalArteries) { isShowingInternalArteries in
            if(isShowingInternalArteries) {
                objectVisualizations.values.forEach { visualization in
                    visualization.showInternalArteries()
                }
            }
            else {
                objectVisualizations.values.forEach { visualization in
                    visualization.hideInternalArteries()
                }
            }
        }
        .onChange(of: showFace) { isShowingFace in
            if(isShowingFace) {
                objectVisualizations.values.forEach { visualization in
                    visualization.showFace()
                }
            }
            else {
                objectVisualizations.values.forEach { visualization in
                    visualization.hideFace()
                }
            }
        }
        .onChange(of: coronalSlice) { slice in
            objectVisualizations.values.forEach { visualization in
                let sliceInt = Int(slice)
                visualization.showCoronalSlice(sliceInt)
            }
        }
        .onChange(of: axialSlice) { slice in
            objectVisualizations.values.forEach { visualization in
                let sliceInt = Int(slice)
                visualization.showAxialSlice(sliceInt)
            }
        }
        .onChange(of: coronalSliceReverse) { slice in
            objectVisualizations.values.forEach { visualization in
                let sliceInt = Int(slice)
                visualization.showCoronalSliceReverse(sliceInt)
            }
        }
        .onChange(of: axialSliceReverse) { slice in
            objectVisualizations.values.forEach { visualization in
                let sliceInt = Int(slice)
                visualization.showAxialSliceReverse(sliceInt)
            }
        }
        .onChange(of: shouldTriggerAnimation) { shouldTriggerAnimation in
            objectVisualizations.values.forEach { visualization in
                if(shouldTriggerAnimation){
                    visualization.playFirstPartOfSkullAnimation()
                }
                else {
                    visualization.playSecondPartOfSkullAnimationInReverse()
                }
            }
        }
        .onAppear() {
            print("Entering immersive space.")
            appState.isImmersiveSpaceOpened = true
        }
        .onDisappear() {
            print("Leaving immersive space.")
            
            for (_, visualization) in objectVisualizations {
                root.removeChild(visualization.entity)
            }
            objectVisualizations.removeAll()
            
            appState.didLeaveImmersiveSpace()
        }
    }
}
