//
//  Utilities.swift
//  KiaAR
//
//  Created by Leandro Demarco Vedelago on 11/12/17.
//  Copyright © 2017 IGS. All rights reserved.
//

import SceneKit

// MARK: SCNNode extension

func createLineNode(fromPos origin: SCNVector3, toPos destination: SCNVector3, color: UIColor) -> SCNNode {
    let line = lineFrom(vector: origin, toVector: destination)
    let lineNode = SCNNode(geometry: line)
    let planeMaterial = SCNMaterial()
    planeMaterial.diffuse.contents = color
    line.materials = [planeMaterial]

    return lineNode
}

func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
    let indices: [Int32] = [0, 1]

    let source = SCNGeometrySource(vertices: [vector1, vector2])
    let element = SCNGeometryElement(indices: indices, primitiveType: .line)

    return SCNGeometry(sources: [source], elements: [element])
}


extension SCNNode {
    func removeAllChildNodes() {
        for childNode in childNodes {
            childNode.removeFromParentNode()
        }
    }

    func setUniformScale(_ scale: Float) {
        self.simdScale = float3(scale, scale, scale)
    }

    func size() -> SCNVector3 {
        let (min, max) = boundingBox
        return SCNVector3Make((max.x - min.x) * scale.x, (max.y - min.y) * scale.y, (max.z - min.z) * scale.z)
    }

    func renderOnTop(_ enable: Bool) {
        self.renderingOrder = enable ? 2 : 0
        if let geom = self.geometry {
            for material in geom.materials {
                material.readsFromDepthBuffer = enable ? false : true
            }
        }
        for child in self.childNodes {
            child.renderOnTop(enable)
        }
    }

    func highlight(withColor color: UIColor = .yellow) {
        let (min, max) = boundingBox
        let nodeH = (max.y - min.y) * scale.y
        let nodeW = (max.x - min.x) * scale.x
        let nodeD = (max.z - min.z) * scale.z

        let frontBottomLeft = SCNVector3Make(-nodeW / 2, -nodeH / 2, -nodeD / 2)
        let frontTopLeft = SCNVector3Make(-nodeW / 2, nodeH / 2, -nodeD / 2)
        let frontTopRight = SCNVector3Make(nodeW / 2, nodeH / 2, -nodeD / 2)
        let frontBottomRight = SCNVector3Make(nodeW / 2, -nodeH / 2, -nodeD / 2)

        let backBottomRight = SCNVector3Make(nodeW / 2, -nodeH / 2, nodeD / 2)
        let backBottomLeft = SCNVector3Make(-nodeW / 2, -nodeH / 2, nodeD / 2)
        let backTopLeft = SCNVector3Make(-nodeW / 2, nodeH / 2, nodeD / 2)
        let backTopRight = SCNVector3Make(nodeW / 2, nodeH / 2, nodeD / 2)

        let line1 = createLineNode(fromPos: frontBottomLeft, toPos: frontBottomRight, color: color)
        let line2 = createLineNode(fromPos: frontBottomRight, toPos: backBottomRight, color: color)
        let line3 = createLineNode(fromPos: backBottomRight, toPos: backBottomLeft, color: color)
        let line4 = createLineNode(fromPos: backBottomLeft, toPos: frontBottomLeft, color: color)
        let line5 = createLineNode(fromPos: frontBottomRight, toPos: frontTopRight, color: color)
        let line6 = createLineNode(fromPos: frontTopRight, toPos: frontTopLeft, color: color)
        let line7 = createLineNode(fromPos: frontTopLeft, toPos: frontBottomLeft, color: color)
        let line8 = createLineNode(fromPos: frontTopRight, toPos: backTopRight, color: color)
        let line9 = createLineNode(fromPos: frontTopLeft, toPos: backTopLeft, color: color)
        let line10 = createLineNode(fromPos: backTopLeft, toPos: backTopRight, color: color)
        let line11 = createLineNode(fromPos: backTopRight, toPos: backBottomRight, color: color)
        let line12 = createLineNode(fromPos: backTopLeft, toPos: backBottomLeft, color: color)

        [line1, line2, line3, line4, line5, line6, line7, line8, line9, line10, line11, line12].forEach {
            addChildNode($0)
        }

    }

    func unhighlight() {
        let highlightningNodes = parent!.childNodes { (child, stop) -> Bool in
            child.name == "highlightNode"
        }
        highlightningNodes.forEach {
            $0.removeFromParentNode()
        }
    }

}

// MARK: CGRect Extension
extension CGRect {
    var mid: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

// MARK: Matrix Extension
extension float4x4 {
    /// Treats matrix as a (right-hand column-major convention) transform matrix
    /// and factors out the translation component of the transform.
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

// MARK: SCNVector extension
extension SCNVector3 {
    static func * (left: SCNVector3, right: Float) -> SCNVector3 {
        return SCNVector3Make(left.x * right, left.y * right, left.z * right)
    }
}

// MARK: - Collection extensions
extension Array where Iterator.Element == Float {
    var average: Float? {
        guard !self.isEmpty else {
            return nil
        }

        let sum = self.reduce(Float(0)) { current, next in
            return current + next
        }
        return sum / Float(self.count)
    }
}

extension Array where Iterator.Element == float3 {
    var average: float3? {
        guard !self.isEmpty else {
            return nil
        }

        let sum = self.reduce(float3(0)) { current, next in
            return current + next
        }
        return sum / Float(self.count)
    }
}

extension RangeReplaceableCollection where IndexDistance == Int {
    mutating func keepLast(_ elementsToKeep: Int) {
        if count > elementsToKeep {
            self.removeFirst(count - elementsToKeep)
        }
    }
}

