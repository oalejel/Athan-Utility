//
//  MoonView3D.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/30/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import Foundation

import SwiftUI
import SceneKit

@available(iOS 13.0.0, *)
struct MoonView3D: View {
    var body: some View {
        GeometryReader { g in
            ZStack {
                ScenekitView()
                    .frame(width: g.size.width, height: g.size.width, alignment: .center)
            }
        }
    }
}

@available(iOS 13.0.0, *)
final class ScenekitView : NSObject, UIViewRepresentable, SCNSceneRendererDelegate, UIGestureRecognizerDelegate {
    let scene = SCNScene()
    let centeredLightParent = SCNNode()
    let centeredCameraParent = SCNNode()
    var pendingRotation = false
    var rotationSemaphore = DispatchSemaphore(value: 1)
    let cameraNode = SCNNode()
    let scnView = SCNView()
    let sphere = SCNNode()
    #warning("might need a dummy binding to get view to update when app updates?")
                
    func makeUIView(context: Context) -> SCNView {
        
        sphere.geometry = SCNSphere(radius: 1)
//        sphere.geometry?.subdivisionLevel = 200
        
        sphere.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "moon_texture.jpg")!
        sphere.geometry?.firstMaterial?.isDoubleSided = true
//        sphere.geometry?.firstMaterial?.normal.contents = UIImage(named: "moon_disp.jpg")!
        scene.rootNode.addChildNode(sphere)
        sphere.position = .init(0, 0, 0)
        scene.rootNode.light = nil
        
        centeredCameraParent.position = .init(x: 0, y: 0, z: 0)
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 80)
        cameraNode.camera?.usesOrthographicProjection = true
        centeredCameraParent.addChildNode(cameraNode)
        scene.rootNode.addChildNode(centeredCameraParent)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor(white: 0.2, alpha: 1)
        scene.rootNode.addChildNode(ambientLightNode)

        
        centeredLightParent.position = .init(x: 0, y: 0, z: 0)

        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 0, z: -70)
//        lightNode.pivot = SCNMatrix4MakeTranslation(0.5, 0.5, 0.5)
        
        centeredLightParent.addChildNode(lightNode)
        scene.rootNode.addChildNode(centeredLightParent)
        
        // retrieve the SCNView
        
        scnView.cameraControlConfiguration.allowsTranslation = false
        scnView.allowsCameraControl = true
        scnView.cameraControlConfiguration.rotationSensitivity = 0.5
        scnView.defaultCameraController.maximumVerticalAngle = 0.0001
        scnView.backgroundColor = UIColor.clear
        scnView.delegate = self
        let gestRec = UIPanGestureRecognizer(target: self, action: #selector(panGesture(g:)))
        gestRec.delegate = self
        scnView.addGestureRecognizer(gestRec)
        
        return scnView
    }
    
    @objc func panGesture(g: UIPanGestureRecognizer) {
        
        print(atan2(scnView.pointOfView!.worldPosition.x, scnView.pointOfView!.worldPosition.z))
//        print(acos(scnView.pointOfView!.worldPosition.x / 80))
        if allowTouches && g.state == .ended { // if done panning, start a 1 second timer to animate back to position
            Timer.scheduledTimer(withTimeInterval: 1.4, repeats: false) { t in
                print("gonna rotate!")
                self.scene.rootNode.removeAllAnimations()
                self.rotateMoon()
            }
        }
    }
    
    var allowTouches = true
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return allowTouches
    }
    
    func rotateMoon() {
        DispatchQueue.main.async {
            self.allowTouches = false
        }
        // since hte method used moves the moon independently of the camera control

        let offsetAngle: CGFloat = CGFloat(atan2(scnView.pointOfView!.worldPosition.x, scnView.pointOfView!.worldPosition.z))
        
        print("rotationg to: ", offsetAngle)
        let sequence = SCNAction.sequence([
            .rotateTo(x: 0, y: offsetAngle, z: 0, duration: 1),
            .run({ node in
                DispatchQueue.main.async {
                    self.allowTouches = true
                }
            })
        ])
        sequence.timingMode = .easeInEaseOut
        scene.rootNode.runAction(sequence)
    }
    
    func rotateLight() {
        // need this check in case we get an unexpected refresh
        rotationSemaphore.wait()
        if pendingRotation {
            rotationSemaphore.signal()
            return
        } else {
            pendingRotation = true
            rotationSemaphore.signal() // let go to let others check
        }
        
        let lastMoonPercent = MoonSettings.lastSeenMoonPercent
        let currentMoonPercent = SwiftySuncalc().getMoonIllumination(date: Date())["phase"]!
        
        // start off on last moon percent
        let startOffset = CGFloat(lastMoonPercent) * CGFloat.pi * 2
        centeredLightParent.simdLocalRotate(by: .init(angle: Float(startOffset), axis: .init(x: 0, y: 1, z: 0)))
        
        var offsetToAnimate: CGFloat = 0
        // case to rotate leftwards and around
        if lastMoonPercent < currentMoonPercent { // ex: 20% -> 50%
            // angle offset will involve a simple difference of percents
            offsetToAnimate = -2 * CGFloat.pi * CGFloat(currentMoonPercent - lastMoonPercent)
        } else {
            // ex: going from 70% to 20%, we still want to animate in natural direction
            offsetToAnimate = -2 * CGFloat.pi * CGFloat((1 - lastMoonPercent) + currentMoonPercent)
        }
        
        centeredLightParent.runAction(.rotate(by: offsetToAnimate, around: .init(0, 1, 0), duration: 2)) {
            self.rotationSemaphore.wait()
            self.pendingRotation = false
            self.rotationSemaphore.signal()
        }
        #warning("todo: save last seen moon percent")
    }
    
    
    


    func updateUIView(_ scnView: SCNView, context: Context) {
        scnView.scene = scene
        
        // always animate light to correct position when view updated
        rotateLight()
    }
}

@available(iOS 13.0.0, *)
struct Moon3DPreview: PreviewProvider {
    static var previews: some View {
        MoonView3D()
    }
}

// MARK: - Last updated moon metadata
// keep track of last angle that user saw when they opened the app.
// default to 0 if none found.
class MoonSettings {
    
    static var lastSeenMoonPercent: Double = {
        UserDefaults.standard.double(forKey: keyName)
    }() {
        didSet {
            UserDefaults.standard.setValue(lastSeenMoonPercent, forKey: keyName)
        }
    }
    private static let keyName = "moonsettings"
}
