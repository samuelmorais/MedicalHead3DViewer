/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main user interface.
*/

import SwiftUI
import ARKit
import RealityKit
import UniformTypeIdentifiers

struct HomeView: View {
    @Bindable var appState: AppState
    let immersiveSpaceIdentifier: String
    
    let referenceObjectUTType = UTType("com.apple.arkit.referenceobject")!

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase
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
    @State private var fileImporterIsOpen = false
    @Binding var shouldTriggerAnimation: Bool
    @State var selectedReferenceObjectID: ReferenceObject.ID?
    @State private var selectedImageIndex: Int? = nil
    var body: some View {
        
        
        Group {
            if appState.canEnterImmersiveSpace {
                referenceObjectList
                    .frame(minWidth: 400, minHeight: 300)
            } else {
                InfoLabel(appState: appState)
                    .padding(.horizontal, 30)
                    .frame(minWidth: 400, minHeight: 300)
                    .fixedSize()
            }
        }
        .glassBackgroundEffect()
        .toolbar {
            ToolbarItem(placement: .bottomOrnament) {
                if appState.canEnterImmersiveSpace {
                    VStack {
                        if !appState.isImmersiveSpaceOpened {
                            Button("Detect \(appState.referenceObjectLoader.enabledReferenceObjectsCount) Patient(s)") {
                                Task {
                                    switch await openImmersiveSpace(id: immersiveSpaceIdentifier) {
                                    case .opened:
                                        break
                                    case .error:
                                        print("An error occurred when trying to open the immersive space \(immersiveSpaceIdentifier)")
                                    case .userCancelled:
                                        print("The user declined opening immersive space \(immersiveSpaceIdentifier)")
                                    @unknown default:
                                        break
                                    }
                                }
                            }
                            .disabled(!appState.canEnterImmersiveSpace || appState.referenceObjectLoader.enabledReferenceObjectsCount == 0)
                        } else {
                            Button("Stop Detecting") {
                                Task {
                                    await dismissImmersiveSpace()
                                    appState.didLeaveImmersiveSpace()
                                }
                            }
                            
                            if !appState.objectTrackingStartedRunning {
                                HStack {
                                    ProgressView()
                                    Text("Please wait until all patient definitions have been loaded")
                                }
                            }
                        }
                        
                        Text(appState.isImmersiveSpaceOpened ?
                             "This leaves the immersive space." :
                             "This enters an immersive space, hiding all other apps."
                        )
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                        .padding(.horizontal)
                    }
                }
            }
        }
        .fileImporter(isPresented: $fileImporterIsOpen, allowedContentTypes: [referenceObjectUTType], allowsMultipleSelection: true) { results in
            switch results {
            case .success(let fileURLs):
                Task {
                    // Try to load each selected file as a reference object.
                    for fileURL in fileURLs {
                        guard fileURL.startAccessingSecurityScopedResource() else {
                            print("Failed to get sandboxed access to the file \(fileURL)")
                            return
                        }
                        await appState.referenceObjectLoader.addReferenceObject(fileURL)
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }
            case .failure(let error):
                print("Failed to open file with error: \(error)")
            }
        }
        .onChange(of: scenePhase, initial: true) {
            print("HomeView scene phase: \(scenePhase)")
            if scenePhase == .active {
                Task {
                    // When returning from the background, check if the authorization has changed.
                    await appState.queryWorldSensingAuthorization()
                }
            } else {
                // Make sure to leave the immersive space if this view is no longer active
                // - such as when a person closes this view - otherwise they may be stuck
                // in the immersive space without the controls this view provides.
                if appState.isImmersiveSpaceOpened {
                    Task {
                        await dismissImmersiveSpace()
                        appState.didLeaveImmersiveSpace()
                    }
                }
            }
        }
        .onChange(of: appState.providersStoppedWithError, { _, providersStoppedWithError in
            // Immediately close the immersive space if an error occurs.
            if providersStoppedWithError {
                if appState.isImmersiveSpaceOpened {
                    Task {
                        await dismissImmersiveSpace()
                        appState.didLeaveImmersiveSpace()
                    }
                }
                
                appState.providersStoppedWithError = false
            }
        })
        .task {
            // Ask for authorization before a person attempts to open the immersive space.
            // This gives the app opportunity to respond gracefully if authorization isn't granted.
            if appState.allRequiredProvidersAreSupported {
                await appState.requestWorldSensingAuthorization()
            }
        }
        .task {
            // Start monitoring for changes in authorization, in case a person brings the
            // Settings app to the foreground and changes authorizations there.
            await appState.monitorSessionEvents()
        }
    }
    
    @MainActor
    var referenceObjectList: some View {
        let imageBindings: [(String, Binding<Bool>)] = [
                    ("skull", $showSkull),
                    ("axial-brain", $showAxialBrain),
                    ("coronal-brain", $showCoronalBrain),
                    ("arterial-head", $showArteries),
                    ("internal-arteries", $showInternalArteries),
                    ("face", $showFace)
                ]
        return NavigationSplitView {
            VStack(alignment: .leading) {
                List(selection: $selectedReferenceObjectID) {
                    ForEach(appState.referenceObjectLoader.referenceObjects, id: \.id) { referenceObject in
                        ListEntryView(referenceObject: referenceObject, referenceObjectLoader: appState.referenceObjectLoader)
                    }
                    .onDelete { indexSet in
                        appState.referenceObjectLoader.removeObjects(atOffsets: indexSet)
                    }
                }
                .navigationTitle("Patient Definitions")

                Button {
                    fileImporterIsOpen = true
                } label: {
                    Image(systemName: "plus")
                }
                .padding(.leading)
                .help("Add reference objects")
            }
            .padding(.vertical)
            .disabled(appState.isImmersiveSpaceOpened)
            
        } detail: {
            if !appState.referenceObjectLoader.didFinishLoading {
                VStack {
                    Text("Loading reference objects…")
                    ProgressView(value: appState.referenceObjectLoader.progress)
                        .frame(maxWidth: 200)
                }
            } else if appState.referenceObjectLoader.referenceObjects.isEmpty {
                Text("Tap the + button to add reference objects, or include some in the 'Reference Objects' group of the app's Xcode project.")
            } else {
                if let selectedObject = appState.referenceObjectLoader.referenceObjects.first(where: { $0.id == selectedReferenceObjectID }) {
                    // Display the USDZ file that the reference object was displayed on in this detail view.
                    if let path = selectedObject.usdzFile, !fileImporterIsOpen {
                        Model3D(url: path) { model in
                            model
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(0.5)
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Text("No preview available")
                    }
                } else {
                    VStack {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 30) {
                            ForEach(0..<imageBindings.count, id: \.self) { index in
                                let (imageName, binding) = imageBindings[index]
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 220, height: 220)
                                    .background(selectedImageIndex == index ? Color.blue.opacity(0.5) : Color.clear) // Highlight when selected
                                    .cornerRadius(10)
                                    .onTapGesture {
                                        // Deselect all and select the tapped image
                                        for (i, imageBinding) in imageBindings.enumerated() {
                                            imageBinding.1.wrappedValue = (i == index)
                                        }
                                        // Update the selected index
                                        selectedImageIndex = index
                                    }
                            }
                        }
                        .padding()
                        
                        // Display controls based on the selected index
                        if selectedImageIndex == 0 {
                            Button(shouldTriggerAnimation ? "Skull Assembly" : "Skull Disassembly") {
                                // Your action
                                shouldTriggerAnimation.toggle()
                            }
                            .padding()
                        }
                        
                        if selectedImageIndex == 2 {
                            HStack {
                                Text("Coronal Slice")
                                Slider(value: $coronalSlice, in: -1...6, step: 1)
                                Slider(value: $coronalSliceReverse, in: 5...12, step: 1)
                            }
                            .padding()
                        }
                        
                        if selectedImageIndex == 1 {
                            HStack {
                                Text("Axial Slice")
                                Slider(value: $axialSlice, in: -1...7, step: 1)
                                Slider(value: $axialSliceReverse, in: 6...13, step: 1)
                            }
                            .padding()
                        }
                    }
                }
            }
        }
    }
}