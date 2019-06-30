//
//  VirtualObjectManager.swift
//  ARDemo
//
//  Created by Leandro Demarco Vedelago on 30/06/2019.
//  Copyright © 2019 LDV. All rights reserved.
//

import Foundation
import ARKit

@available(iOS 11.0, *)
class VirtualObjectManager {
    var updateQueue: DispatchQueue

    init(updateQueue: DispatchQueue) {
        self.updateQueue = updateQueue
    }

    func worldPositionFromScreenPosition(
        _ position: CGPoint,
        in sceneView: ARSCNView,
        objectPos: float3?,
        infinitePlane: Bool = false) ->
        (position: float3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool)
    {
        //let dragOnInfinitePlanesEnabled = false //UserDefaults.standard.bool(for: .dragOnInfinitePlanes)

        // -------------------------------------------------------------------------------
        // 1. Always do a hit test against exisiting plane anchors first.
        //    (If any such anchors exist & only within their extents.)

        let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {

            let planeHitTestPosition = result.worldTransform.translation
            let planeAnchor = result.anchor

            // Return immediately - this is the best possible outcome.
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }

        // -------------------------------------------------------------------------------
        // 2. Collect more information about the environment by hit testing against
        //    the feature point cloud, but do not return the result yet.

        var featureHitTestPosition: float3?
        var highQualityFeatureHitTestResult = false

        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(
            position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)

        if !highQualityfeatureHitTestResults.isEmpty {
            let result = highQualityfeatureHitTestResults[0]
            featureHitTestPosition = result.position
            highQualityFeatureHitTestResult = true
        }

        // -------------------------------------------------------------------------------
        // 3. If desired or necessary (no good feature hit test result): Hit test
        //    against an infinite, horizontal plane (ignoring the real world).

        //        if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {
        //
        //            if let pointOnPlane = objectPos {
        //                let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
        //                if pointOnInfinitePlane != nil {
        //                    return (pointOnInfinitePlane, nil, true)
        //                }
        //            }
        //        }

        // -------------------------------------------------------------------------------
        // 4. If available, return the result of the hit test against high quality
        //    features if the hit tests against infinite planes were skipped or no
        //    infinite plane was hit.

        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }

        // -------------------------------------------------------------------------------
        // 5. As a last resort, perform a second, unfiltered hit test against features.
        //    If there are no features in the scene, the result returned here will be nil.

        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }

        return (nil, nil, false)
    }
}
