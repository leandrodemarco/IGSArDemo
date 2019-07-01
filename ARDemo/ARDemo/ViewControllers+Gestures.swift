//
//  ViewControllers+Gestures.swift
//  ARKitTestKia
//
//  Created by Leandro Demarco Vedelago on 15/12/17.
//  Copyright © 2017 PitBoxMedia. All rights reserved.
//

import UIKit
import SceneKit

extension ViewController {
    @objc func onDrag(_ sender: UIPanGestureRecognizer) {
        /* Move car in the XZ plane.
           Vertical pan moves it along the Z axis (closer/further from camera)
           Horizontal pan moves it along the X axis
        */

        let position = sender.location(in: sceneView)
        let state = sender.state

        if (state == .failed || state == .cancelled) {
            return
        }

        if (state == .began) {
            // Check it's on a the car
            let hitResults = performHitTestAtPosition(position, maxRadius: 10.0, radiusInterval: 1.0)
            if hitResults.count > 0 {
                latestDragPos = position
            }

        }
        else if let _ = latestDragPos {

            // Translate virtual object
            let deltaX = Float(position.x - latestDragPos!.x)/350
            let deltaY = Float(position.y - latestDragPos!.y)/350
            guard let parentNode = masterNode /*bodyNode.parent*/ else { return }
            parentNode.localTranslate(by: SCNVector3Make(deltaX, 0.0, deltaY))

            latestDragPos = position

            if (state == .ended) {
                latestDragPos = nil
            }
        }
    }

    @objc func onRotate(_ sender: UIRotationGestureRecognizer) {
        // Rotate around Y axis
        let position = sender.location(in: sceneView)
        let state = sender.state

        if state == .failed || state == .cancelled {
            return
        }

        // Negative rotation is counterclockwise, positive is clockwise. Rotation is around Y axis
        if state == .began {
            // Check it's on a virtual object
            let hitResults = performHitTestAtPosition(position, maxRadius: 10.0, radiusInterval: 1.0)
            if hitResults.count > 0 {
                latestRotationAngle = 0
            }
        }
        else if let _ = latestRotationAngle {
            let newRotation = sender.rotation
            let deltaRotation = newRotation - latestRotationAngle!

            let rotationAngle = (Float(-deltaRotation) * Float.pi) / 5.0
            guard let parent = masterNode /*bodyNode.parent*/ else { return }

            parent.runAction(SCNAction.rotateBy(x: 0.0, y: CGFloat(rotationAngle), z: 0.0, duration: 0.1))
            latestRotationAngle = newRotation

            if state == .ended {
                latestRotationAngle = nil
            }
        }
    }
}
