/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The visualization of an object anchor.
*/

import ARKit
import RealityKit
import SwiftUI
import RealityKitContent
@MainActor
class ObjectAnchorVisualization {
    
    private let textBaseHeight: Float = 0.08
    private let alpha: CGFloat = 0.7
    private let axisScale: Float = 0.05
    
    var boundingBoxOutline: BoundingBoxOutline
    
    var entity: Entity
    var headEntity: Entity
    var skull: Entity?
    var brainAxial: Entity?
    var brainCoronal: Entity?
    var arteries: Entity?
    var internalArteries: Entity?
    var face: Entity?
    var coronalSlices: [Entity] = []
    var axialSlices: [Entity] = []
    private let animationDuration = 0.5
    var lastAxialSlice: Int = 0
    var lastCoronalSlice: Int = 0
    var lastAxialSliceReverse: Int = 12
    var lastCoronalSliceReverse: Int = 11
    private let halfOpacity: Float = 0.25
    enum EntityType {
        case skull, brainAxial, brainCoronal, arteries, internalArteries, face
    }
    
    init(for anchor: ObjectAnchor, withModel model: Entity? = nil) async {
        boundingBoxOutline = BoundingBoxOutline(anchor: anchor, alpha: alpha)
        let entity = Entity()
        self.headEntity = Entity()
        if let immersiveContentEntity = try? await Entity(named: "Assets/HeadScene", in: realityKitContentBundle) {
            headEntity = immersiveContentEntity
            entity.addChild(headEntity)
            //immersiveContentEntity.position = [0, 1.0, -0.5]
            // Put skybox here.  See example in World project available at
            // https://developer.apple.com/
            //If find skull as child of headEntity, assign to the skull variable:
            skull = immersiveContentEntity.findEntity(named: "Skull_Anim")
            brainAxial = immersiveContentEntity.findEntity(named: "BrainAxial")
            brainCoronal = immersiveContentEntity.findEntity(named: "BrainCoronal")
            arteries = immersiveContentEntity.findEntity(named: "Arteries")
            internalArteries = immersiveContentEntity.findEntity(named: "InternalArteries")
            face = immersiveContentEntity.findEntity(named: "Face")
            //If find coronal slices as children of headEntity, assign to the coronalSlices variable:
            for i in 1...12 {
                if let coronalSlice = immersiveContentEntity.findEntity(named: "Coronal_Slice_\(i)") {
                    print("Found coronal slice \(i)")
                    coronalSlices.append(coronalSlice)
                }
            }
            //If find axial slices as children of headEntity, assign to the axialSlices variable:
            for i in 1...13 {
                if let axialSlice = immersiveContentEntity.findEntity(named: "Axial_Slice_\(i)") {
                    print("Found axial slice \(i)")
                    axialSlices.append(axialSlice)
                }
            }
        }
        let originVisualization = Entity.createAxes(axisScale: axisScale, alpha: alpha)
        
        if let model {
            // Overwrite the model's appearance to a yellow wireframe.
            var wireframeMaterial = PhysicallyBasedMaterial()
            wireframeMaterial.triangleFillMode = .lines
            wireframeMaterial.faceCulling = .back
            wireframeMaterial.baseColor = .init(tint: .yellow)
            wireframeMaterial.blending = .transparent(opacity: 0.5)
            
            model.applyMaterialRecursively(wireframeMaterial)
            //entity.addChild(model)
        }
        
        boundingBoxOutline.entity.isEnabled = model == nil
        
        //entity.addChild(originVisualization)
        entity.addChild(boundingBoxOutline.entity)
        
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        entity.isEnabled = anchor.isTracked
        
        /*let descriptionEntity = Entity.createText(anchor.referenceObject.name, height: textBaseHeight * axisScale)
        descriptionEntity.transform.translation.x = textBaseHeight * axisScale
        descriptionEntity.transform.translation.y = anchor.boundingBox.extent.y * 0.5
        entity.addChild(descriptionEntity)*/
        self.entity = entity
    }
    
    func update(with anchor: ObjectAnchor) {
        entity.isEnabled = anchor.isTracked
        guard anchor.isTracked else { return }
        
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        boundingBoxOutline.update(with: anchor)
    }
    
    func showSkull() {
        fadeOutAllExcept(except: .skull)
        fadeInEntity(someEntity: skull!)
    }
    
    func showBrainAxial() {
        fadeOutAllExcept(except: .brainAxial)
        fadeInEntity(someEntity: brainAxial!)
    }
    
    func showBrainCoronal() {
        fadeOutAllExcept(except: .brainCoronal)
        fadeInEntity(someEntity: brainCoronal!)
    }
    
    func showArteries() {
        fadeOutAllExcept(except: .arteries)
        fadeInEntity(someEntity: arteries!)
    }
    
    func showInternalArteries() {
        fadeOutAllExcept(except: .internalArteries)
        fadeInEntity(someEntity: internalArteries!)
    }
    
    func showFace() {
        fadeOutAllExcept(except: .face)
        fadeInEntityHalf(someEntity: face!)
    }
    
    func hideFace() {
        fadeOutEntityHalf(someEntity: face!)
    }
    
    func hideInternalArteries() {
        fadeOutEntity(someEntity: internalArteries!)
    }
    
    func hideArteries() {
        fadeOutEntity(someEntity: arteries!)
    }
    
    func hideBrainCoronal() {
        fadeOutEntity(someEntity: brainCoronal!)
    }
    
    func hideBrainAxial() {
        fadeOutEntity(someEntity: brainAxial!)
    }
    
    func hideSkull() {
        fadeOutEntity(someEntity: skull!)
    }
    
    func hideAll() {
        skull?.isEnabled = false
        brainAxial?.isEnabled = false
        brainCoronal?.isEnabled = false
        arteries?.isEnabled = false
        internalArteries?.isEnabled = false
        face?.isEnabled = false
    }
    
    func showAll() {
        skull?.isEnabled = true
        brainAxial?.isEnabled = true
        brainCoronal?.isEnabled = true
        arteries?.isEnabled = true
        internalArteries?.isEnabled = true
        face?.isEnabled = true
    }
    
    func showCoronalSlice(_ index: Int) {
        lastCoronalSlice = index
        displayRangeCoronal()
    }
    
    func showCoronalSliceReverse(_ index: Int) {
        lastCoronalSliceReverse = index
        displayRangeCoronal()
    }
    
    func displayRangeCoronal() {
        for i in 0...11 {
            if(i >= lastCoronalSlice && i <= lastCoronalSliceReverse) {
                if(!coronalSlices[i].isEnabled) {
                    fadeInEntity(someEntity: coronalSlices[i])
                }
            }
            else {
                if(coronalSlices[i].isEnabled) {
                    fadeOutEntity(someEntity: coronalSlices[i])
                }
            }
        }
    }
    
    func playFirstAnimationOfSkullEntity() {
        skull?.playAnimation(skull!.availableAnimations[0].repeat(count: 1))
    }
    
    func playFirstPartOfSkullAnimation() {
        guard let skull = skull else { return }
        let view = AnimationView(source: skull.availableAnimations[0].definition,
            name: "clip",
            bindTarget: nil,
            blendLayer: 0,
            repeatMode: .none,
            fillMode: [],
            trimStart: 0.0,
            trimEnd: 4.0,
            trimDuration: nil,
            offset: 0,
            delay: 0,
            speed: 1.0)
        // Create an animation resource from the clip.
        let clipResource = try? AnimationResource.generate(with: view)
        skull.playAnimation(clipResource!)
        /*
        // Fade out opacity during the animation
        let fadeOutDuration: Double = 0.5
        let fadeOutAnimationDefinition = FromToByAnimation(from: Float(1.0), to: Float(0.0), duration: fadeOutDuration, bindTarget: .opacity)
        if let fadeOutAnimation = try? AnimationResource.generate(with: fadeOutAnimationDefinition) {
            skull.playAnimation(fadeOutAnimation)
        }*/
    }

    func playSecondPartOfSkullAnimationInReverse() {
        guard let skull = skull else { return }
        let view = AnimationView(source: skull.availableAnimations[0].definition,
            name: "clip",
            bindTarget: nil,
            blendLayer: 0,
            repeatMode: .none,
            fillMode: [],
            trimStart: 4.0,
            trimEnd: 8.0,
            trimDuration: nil,
            offset: 0,
            delay: 0,
            speed: 1.0)
        // Create an animation resource from the clip.
        let clipResource = try? AnimationResource.generate(with: view)
        skull.playAnimation(clipResource!)
        
        /*
        
        // Fade in opacity during the animation
        let fadeInDuration: Double = 0.5
        let fadeInAnimationDefinition = FromToByAnimation(from: Float(0.0), to: Float(1.0), duration: fadeInDuration, bindTarget: .opacity)
        if let fadeInAnimation = try? AnimationResource.generate(with: fadeInAnimationDefinition) {
            skull.playAnimation(fadeInAnimation)
        }*/
    }
    
    func showAxialSlice(_ index: Int) {
        lastAxialSlice = index
        displayRangeAxial()
    }
    
    func showAxialSliceReverse(_ index: Int) {
        lastAxialSliceReverse = index
        displayRangeAxial()
    }
    
    func displayRangeAxial() {
        for i in 0...12 {
            if(i >= lastAxialSlice && i <= lastAxialSliceReverse) {
                if(!axialSlices[i].isEnabled) {
                    fadeInEntityQuickly(someEntity: axialSlices[i])
                }
            }
            else {
                if(axialSlices[i].isEnabled) {
                    fadeOutEntityQuickly(someEntity: axialSlices[i])
                }
            }
        }
    }
    
    
    func fadeOutEntity(someEntity: Entity) {
        let animationDefinition = FromToByAnimation(from: Float(1.0), to: Float(0.0), duration: animationDuration, bindTarget: .opacity)
        if let animationResource = try? AnimationResource.generate(with: animationDefinition) {
            someEntity.playAnimation(animationResource)
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                someEntity.isEnabled = false
            }
        }
    }
    
    func fadeInEntity(someEntity: Entity) {
        someEntity.isEnabled = true
        let animationDefinition = FromToByAnimation(from: Float(0.0), to: Float(1.0), duration: animationDuration, bindTarget: .opacity)
        if let animationResource = try? AnimationResource.generate(with: animationDefinition) {
            someEntity.playAnimation(animationResource)
        }
    }
    
    func fadeInEntityHalf(someEntity: Entity) {
        someEntity.isEnabled = true
        let animationDefinition = FromToByAnimation(from: Float(0.0), to: Float(halfOpacity), duration: animationDuration, bindTarget: .opacity)
        if let animationResource = try? AnimationResource.generate(with: animationDefinition) {
            someEntity.playAnimation(animationResource)
        }
    }
    
    func fadeOutEntityHalf(someEntity: Entity) {
        let animationDefinition = FromToByAnimation(from: Float(halfOpacity), to: Float(0.0), duration: animationDuration, bindTarget: .opacity)
        if let animationResource = try? AnimationResource.generate(with: animationDefinition) {
            someEntity.playAnimation(animationResource)
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                someEntity.isEnabled = false
            }
        }
    }
    
    func fadeOutEntityQuickly(someEntity: Entity) {
        let animationDefinition = FromToByAnimation(from: Float(1.0), to: Float(0.0), duration: 0.1, bindTarget: .opacity)
        if let animationResource = try? AnimationResource.generate(with: animationDefinition) {
            someEntity.playAnimation(animationResource)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                someEntity.isEnabled = false
            }
        }
    }
    
    func fadeInEntityQuickly(someEntity: Entity) {
        someEntity.isEnabled = true
        let animationDefinition = FromToByAnimation(from: Float(0.0), to: Float(1.0), duration: 0.1, bindTarget: .opacity)
        if let animationResource = try? AnimationResource.generate(with: animationDefinition) {
            someEntity.playAnimation(animationResource)
        }
    }
    
    func fadeOutAllExcept(except entityType: EntityType) {
        let animationDuration: Double = 0.25

        // Define a closure to handle fading out entities
        let fadeOutIfEnabled: (Entity?) -> Void = { entity in
            if let entity = entity, entity.isEnabled {
                let animationDefinition = FromToByAnimation(from: Float(1.0), to: Float(0.0), duration: animationDuration, bindTarget: .opacity)
                if let animationResource = try? AnimationResource.generate(with: animationDefinition) {
                    entity.playAnimation(animationResource)
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        entity.isEnabled = false
                    }
                }
            }
        }
        
        let fadeOutIfEnabledHalf: (Entity?) -> Void = { entity in
            if let entity = entity, entity.isEnabled {
                let animationDefinition = FromToByAnimation(from: Float(self.halfOpacity), to: Float(0.0), duration: animationDuration, bindTarget: .opacity)
                if let animationResource = try? AnimationResource.generate(with: animationDefinition) {
                    entity.playAnimation(animationResource)
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        entity.isEnabled = false
                    }
                }
            }
        }

        // Iterate over all entities and fade out those that do not match `entityType`
        switch entityType {
        case .skull:
            fadeOutIfEnabled(brainAxial)
            fadeOutIfEnabled(brainCoronal)
            fadeOutIfEnabled(arteries)
            fadeOutIfEnabled(internalArteries)
            fadeOutIfEnabledHalf(face)
        case .brainAxial:
            fadeOutIfEnabled(skull)
            fadeOutIfEnabled(brainCoronal)
            fadeOutIfEnabled(arteries)
            fadeOutIfEnabled(internalArteries)
            fadeOutIfEnabledHalf(face)
        case .brainCoronal:
            fadeOutIfEnabled(skull)
            fadeOutIfEnabled(brainAxial)
            fadeOutIfEnabled(arteries)
            fadeOutIfEnabled(internalArteries)
            fadeOutIfEnabledHalf(face)
        case .arteries:
            fadeOutIfEnabled(skull)
            fadeOutIfEnabled(brainAxial)
            fadeOutIfEnabled(brainCoronal)
            fadeOutIfEnabled(internalArteries)
            fadeOutIfEnabledHalf(face)
        case .internalArteries:
            fadeOutIfEnabled(skull)
            fadeOutIfEnabled(brainAxial)
            fadeOutIfEnabled(brainCoronal)
            fadeOutIfEnabled(arteries)
            fadeOutIfEnabledHalf(face)
        case .face:
            fadeOutIfEnabled(skull)
            fadeOutIfEnabled(brainAxial)
            fadeOutIfEnabled(brainCoronal)
            fadeOutIfEnabled(arteries)
            fadeOutIfEnabled(internalArteries)
        }
    }
    
    
    @MainActor
    class BoundingBoxOutline {
        private let thickness: Float = 0.0025
        
        private var extent: SIMD3<Float> = [0, 0, 0]
        
        private var wires: [Entity] = []
        
        var entity: Entity

        fileprivate init(anchor: ObjectAnchor, color: UIColor = .yellow, alpha: CGFloat = 1.0) {
            let entity = Entity()
            
            let materials = [UnlitMaterial(color: color.withAlphaComponent(alpha))]
            let mesh = MeshResource.generateBox(size: [1.0, 1.0, 1.0])

            for _ in 0...11 {
                let wire = ModelEntity(mesh: mesh, materials: materials)
                wires.append(wire)
                entity.addChild(wire)
            }
            
            self.entity = entity
            
            update(with: anchor)
        }
        
        fileprivate func update(with anchor: ObjectAnchor) {
            entity.transform.translation = anchor.boundingBox.center
            
            // Update the outline only if the extent has changed.
            guard anchor.boundingBox.extent != extent else { return }
            extent = anchor.boundingBox.extent

            for index in 0...3 {
                wires[index].scale = SIMD3<Float>(extent.x, thickness, thickness)
                wires[index].position = [0, extent.y / 2 * (index % 2 == 0 ? -1 : 1), extent.z / 2 * (index < 2 ? -1 : 1)]
            }
            
            for index in 4...7 {
                wires[index].scale = SIMD3<Float>(thickness, extent.y, thickness)
                wires[index].position = [extent.x / 2 * (index % 2 == 0 ? -1 : 1), 0, extent.z / 2 * (index < 6 ? -1 : 1)]
            }
            
            for index in 8...11 {
                wires[index].scale = SIMD3<Float>(thickness, thickness, extent.z)
                wires[index].position = [extent.x / 2 * (index % 2 == 0 ? -1 : 1), extent.y / 2 * (index < 10 ? -1 : 1), 0]
            }
        }
    }
}
