//
//  PanoramaView.swift
//  InnSight
//
//  Vista panorámica 360° usando SceneKit con soporte de giroscopio
//

import SwiftUI
import SceneKit
import Combine
import CoreMotion

struct PanoramaView: View {
    let imageUrl: String
    let roomName: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var loader = PanoramaImageLoader()
    @State private var useGyroscope = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if loader.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Cargando vista 360°...")
                        .foregroundColor(.white)
                        .font(AppFonts.bodyMedium)
                }
            } else if let error = loader.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.white)
                        .font(AppFonts.bodyMedium)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Reintentar") {
                        loader.loadImage(from: imageUrl)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.primary)
                    .cornerRadius(8)
                }
            } else if let image = loader.image {
                PanoramaSceneView(image: image, useGyroscope: useGyroscope)
                    .ignoresSafeArea()
            }
            
            // Overlay UI
            VStack {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Gyroscope toggle
                    Button {
                        useGyroscope.toggle()
                    } label: {
                        Image(systemName: useGyroscope ? "gyroscope" : "hand.draw")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(useGyroscope ? AppColors.primary.opacity(0.8) : Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Vista 360°")
                            .font(AppFonts.labelMedium)
                            .foregroundColor(.white.opacity(0.8))
                        Text(roomName)
                            .font(AppFonts.titleSmall)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // Instructions
                if !loader.isLoading && loader.errorMessage == nil && loader.image != nil {
                    HStack(spacing: 20) {
                        if useGyroscope {
                            instructionItem(icon: "iphone.gen3.radiowaves.left.and.right", text: "Mueve el teléfono")
                        } else {
                            instructionItem(icon: "hand.draw", text: "Desliza para girar")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loader.loadImage(from: imageUrl)
        }
    }
    
    private func instructionItem(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            Text(text)
                .font(AppFonts.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Image Loader

@MainActor
class PanoramaImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadImage(from urlString: String) {
        isLoading = true
        errorMessage = nil
        image = nil
        
        guard let url = URL(string: urlString) else {
            errorMessage = "URL de imagen inválida"
            isLoading = false
            return
        }
        
        print("🔄 Cargando imagen 360° desde: \(urlString)")
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    errorMessage = "Error al descargar la imagen"
                    isLoading = false
                    return
                }
                
                guard let loadedImage = UIImage(data: data) else {
                    errorMessage = "No se pudo procesar la imagen"
                    isLoading = false
                    return
                }
                
                print("✅ Imagen 360° cargada: \(loadedImage.size)")
                image = loadedImage
                isLoading = false
            } catch {
                print("❌ Error cargando imagen 360°: \(error)")
                errorMessage = "Error: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

// MARK: - SceneKit Panorama View with Gyroscope

struct PanoramaSceneView: UIViewRepresentable {
    let image: UIImage
    let useGyroscope: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = SCNScene()
        sceneView.backgroundColor = .black
        sceneView.autoenablesDefaultLighting = false
        
        // Create camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 80
        cameraNode.position = SCNVector3(0, 0, 0)
        cameraNode.name = "camera"
        sceneView.scene?.rootNode.addChildNode(cameraNode)
        sceneView.pointOfView = cameraNode
        
        // Create sphere with panorama texture
        let sphere = SCNSphere(radius: 10)
        sphere.segmentCount = 96
        
        let material = SCNMaterial()
        material.diffuse.contents = image
        material.isDoubleSided = true
        material.cullMode = .front
        sphere.materials = [material]
        
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(0, 0, 0)
        sphereNode.scale = SCNVector3(-1, 1, 1)
        
        sceneView.scene?.rootNode.addChildNode(sphereNode)
        
        // Store reference
        context.coordinator.sceneView = sceneView
        context.coordinator.cameraNode = cameraNode
        
        // Add pan gesture for manual control
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        // Add pinch gesture for zoom
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        if useGyroscope {
            context.coordinator.startGyroscope()
        } else {
            context.coordinator.stopGyroscope()
        }
    }
    
    static func dismantleUIView(_ uiView: SCNView, coordinator: Coordinator) {
        coordinator.stopGyroscope()
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject {
        var sceneView: SCNView?
        var cameraNode: SCNNode?
        
        private let motionManager = CMMotionManager()
        private var isGyroscopeActive = false
        private var referenceAttitude: CMAttitude?
        
        // Camera rotation state
        private var currentPitch: Float = 0
        private var currentYaw: Float = 0
        
        // For pan gesture
        private var lastPanPoint: CGPoint = .zero
        
        func startGyroscope() {
            guard !isGyroscopeActive else { return }
            guard motionManager.isDeviceMotionAvailable else {
                print("⚠️ Device motion not available")
                return
            }
            
            isGyroscopeActive = true
            referenceAttitude = nil
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            
            motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: .main) { [weak self] motion, error in
                guard let self = self, let motion = motion else { return }
                
                // Capturar la orientación inicial como referencia
                if self.referenceAttitude == nil {
                    self.referenceAttitude = motion.attitude.copy() as? CMAttitude
                }
                
                // Calcular la diferencia desde la orientación inicial
                if let reference = self.referenceAttitude {
                    motion.attitude.multiply(byInverseOf: reference)
                }
                
                let attitude = motion.attitude
                
                // Convertir a rotación de cámara
                // El teléfono se sostiene en posición vertical (portrait)
                let pitch = Float(attitude.pitch)
                let yaw = Float(attitude.yaw)
                
                // Aplicar rotación - ajustado para que mire al frente cuando el teléfono está vertical
                self.cameraNode?.eulerAngles = SCNVector3(
                    pitch,   // Arriba/abajo
                    -yaw,    // Izquierda/derecha
                    0
                )
            }
            
            print("🎯 Giroscopio activado")
        }
        
        func stopGyroscope() {
            guard isGyroscopeActive else { return }
            motionManager.stopDeviceMotionUpdates()
            isGyroscopeActive = false
            referenceAttitude = nil
            print("🎯 Giroscopio desactivado")
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard !isGyroscopeActive else { return }
            guard let view = gesture.view else { return }
            
            let translation = gesture.translation(in: view)
            
            if gesture.state == .began {
                lastPanPoint = .zero
            }
            
            let deltaX = Float(translation.x - lastPanPoint.x) * 0.005
            let deltaY = Float(translation.y - lastPanPoint.y) * 0.005
            
            currentYaw -= deltaX
            currentPitch -= deltaY
            
            // Clamp pitch to prevent flipping
            currentPitch = max(-.pi / 2 + 0.1, min(.pi / 2 - 0.1, currentPitch))
            
            cameraNode?.eulerAngles = SCNVector3(currentPitch, currentYaw, 0)
            
            lastPanPoint = CGPoint(x: translation.x, y: translation.y)
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let camera = cameraNode?.camera else { return }
            
            if gesture.state == .changed {
                let newFOV = camera.fieldOfView / Double(gesture.scale)
                camera.fieldOfView = max(30, min(120, newFOV))
                gesture.scale = 1.0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PanoramaView(
        imageUrl: "https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=2048",
        roomName: "Suite Deluxe 101"
    )
}
