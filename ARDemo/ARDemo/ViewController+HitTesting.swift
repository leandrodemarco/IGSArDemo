//
//  ViewController+HitTesting.swift
//  ARKitTestKia
//
//  Created by Leandro Demarco Vedelago on 13/12/17.
//  Copyright © 2017 PitBoxMedia. All rights reserved.
//

import SceneKit

extension ViewController {
    // MARK: General hit test method
    func performHitTestAtPosition(_ point: CGPoint, maxRadius: CGFloat = 30, radiusInterval: CGFloat = 1) -> [SCNHitTestResult] {
        // If hit test at point fails try looking around a bit
        func pointsAround(_ point: CGPoint, radius: CGFloat) -> [CGPoint] {
            let originX = point.x
            let originY = point.y

            return [CGPoint(x: originX + radius, y: originY),
                    CGPoint(x: originX, y: originY + radius),
                    CGPoint(x: originX - radius, y: originY),
                    CGPoint(x: originX, y: originY - radius)]
        }

        let hitTestOptions: [SCNHitTestOption : Any] = [.boundingBoxOnly: false, .searchMode: SCNHitTestSearchMode.all.rawValue]
        var hitTestResults: [SCNHitTestResult] = sceneView.hitTest(point, options: hitTestOptions)

        var finishedLooking = hitTestResults.count > 0
        var currentRadius = radiusInterval
        while (!finishedLooking) {
            let nextPoints = pointsAround(point, radius: currentRadius)
            for nPoint in nextPoints {
                hitTestResults = sceneView.hitTest(nPoint, options: hitTestOptions)
                if hitTestResults.count > 0 {
                    finishedLooking = true
                    break
                }
            }
            currentRadius += currentRadius
            if currentRadius > maxRadius { finishedLooking = true }
        }

        return hitTestResults
    }

    // Door hit testing methods
    func doorBelongingToNode(_ node: SCNNode) -> Door? {
        if nodeBelongsToDoor(node, frontLeftDoor) { return frontLeftDoor }
        if nodeBelongsToDoor(node, frontRightDoor) { return frontRightDoor }
        if nodeBelongsToDoor(node, backLeftDoor) { return backLeftDoor }
        if nodeBelongsToDoor(node, backRightDoor) { return backRightDoor }
        return nil
    }

    private func nodeBelongsToDoor(_ node: SCNNode, _ door: Door) -> Bool {
        let isOpen = door.isOpen
        let doorName = door.name
        var targetNode: SCNNode?
        var res = false

        switch doorName {
        case .frontRight:
            targetNode = isOpen ? frontRightOpened : frontRightClosed
        case .frontLeft:
            targetNode = isOpen ? frontLeftOpened : frontLeftClosed
        case .backLeft:
            targetNode = isOpen ? rearLeftOpened : rearLeftClosed
        case .backRight:
            targetNode = isOpen ? rearRightOpened : rearRightClosed
        default:
            break
        }


        if let targetNode = targetNode {
            targetNode.enumerateChildNodes({ (child, stop) in
                if node === child {
                    res = true
                    stop.pointee = true
                }
            })
        }

        return res
    }

}
