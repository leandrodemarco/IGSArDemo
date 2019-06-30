//
//  ViewController+KiaNodes.swift
//  ARKitTestKia
//
//  Created by Leandro Demarco Vedelago on 12/12/17.
//  Copyright © 2017 PitBoxMedia. All rights reserved.
//

import SceneKit
import SceneKit.ModelIO

enum DoorsName: String {
    case frontRight
    case frontLeft
    case backRight
    case backLeft
    case back
}

class Door {
    let name: DoorsName
    var isOpen = false
    var isAnimating = false

    init(name: DoorsName) {
        self.name = name
    }

    func toogleState() {
        isAnimating = false // Animation just finished
        isOpen = !isOpen
    }
}

private let bikeMountNodeNames = ["black_body3", "black_details", "black_frame", "bike_mount", "body", "body_mount", "bolts", "bulbs", "chrome_frame",
                                  "clear_glass", "frame", "mount_part", "mount_part1", "mount_part2", "red_glass", "reflectors", "white_surface",
                                  "orange_bulb", "fluted_reflectors"]
private let bikeMountReactiveNodeNames = ["Trunk", "Trunk_lock", "Trunk_part", "Bumper_rear", "Bumper_rear_part1"]


extension ViewController {

    func loadATMNode() {
        let url = Bundle.main.url(forResource: "ATM", withExtension: ".obj", subdirectory: "art.scnassets")
        let asset = MDLAsset(url: url!)
        let object = asset.object(at: 0) as! MDLMesh
        let scatFunction = MDLScatteringFunction()
        let material = MDLMaterial.init(name: "atmMaterial", scatteringFunction: scatFunction)

        let materialURL = Bundle.main.url(forResource: "atm", withExtension: ".jpg", subdirectory: "art.scnassets")
        let baseColorProperty = MDLMaterialProperty.init(name: "baseColor", semantic: .baseColor)
        baseColorProperty.type = .texture
        baseColorProperty.urlValue = materialURL!
        material.setProperty(baseColorProperty)

        if let submeshes = object.submeshes {
            for (_, submesh) in submeshes.enumerated() {
                if let castedSubmesh = submesh as? MDLSubmesh {
                    castedSubmesh.material = material
                }
            }
        }

        atmNode = SCNNode.init(mdlObject: object)
        atmNode.scale = SCNVector3Make(0.001, 0.001, 0.001)
    }

    func loadCarNodes() {
        bodyNode = loadNodeNamed("KIA-BODY-04.DAE")

        var foundBikeParts: [String] = []
        var foundReactParts: [String] = []
        bodyNode.enumerateChildNodes { (child, stop) in
            if let childName = child.name {
                if bikeMountNodeNames.contains(childName) {
                    foundBikeParts.append(childName)
                    bikeMountNodes.append(child)
                } else if bikeMountReactiveNodeNames.contains(childName) {
                    foundReactParts.append(childName)
                    bikeMountReactNodes.append(child)
                }
            }
        }
        #if DEBUG
            print("Found \(foundBikeParts.count) of \(bikeMountNodeNames.count) bike parts")
            print("Found \(foundReactParts.count) of \(bikeMountReactiveNodeNames.count) react parts")
            let unfoundBikeParts = Set(bikeMountNodeNames).subtracting(Set(foundBikeParts))
            let unfoundReactParts = Set(bikeMountReactiveNodeNames).subtracting(Set(foundReactParts))
            unfoundBikeParts.forEach { print("Could not find bike part: \($0)") }
            unfoundReactParts.forEach { print("Could not find react part: \($0)") }
        #endif

        rearLeftOpen = loadNodeNamed("DOOR-REAR-L-abre.DAE")
        rearLeftClose = loadNodeNamed("DOOR-REAR-L-cierra.DAE")
        rearLeftOpened = loadNodeNamed("DOOR-REAR-L-abierta.DAE")
        rearLeftClosed = loadNodeNamed("DOOR-REAR-L-cerrada.DAE")

        rearRightOpen = loadNodeNamed("DOOR-REAR-R-abre.DAE")
        rearRightClose = loadNodeNamed("DOOR-REAR-R-cierra.DAE")
        rearRightOpened = loadNodeNamed("DOOR-REAR-R-abierta.DAE")
        rearRightClosed = loadNodeNamed("DOOR-REAR-R-cerrada.DAE")

        frontLeftOpen = loadNodeNamed("DOOR-FRONT-L-abre.DAE")
        frontLeftClose = loadNodeNamed("DOOR-FRONT-L-cierra.DAE")
        frontLeftOpened = loadNodeNamed("DOOR-FRONT-L-abierta.DAE")
        frontLeftClosed = loadNodeNamed("DOOR-FRONT-L-cerrada.DAE")

        frontRightOpen = loadNodeNamed("DOOR-FRONT-R-abre.DAE")
        frontRightClose = loadNodeNamed("DOOR-FRONT-R-cierra.DAE")
        frontRightOpened = loadNodeNamed("DOOR-FRONT-R-abierta.DAE")
        frontRightClosed = loadNodeNamed("DOOR-FRONT-R-cerrada.DAE")
    }

    private func loadNodeNamed(_ name: String) -> SCNNode? {
        guard let scene = SCNScene(named: "art.scnassets/" + name) else {
            print("ERROR: Failed to load node named \(name)")
            return nil
        }

        let node = SCNNode()
        let childrenNodes = scene.rootNode.childNodes
        for child in childrenNodes {
            node.addChildNode(child as SCNNode)
        }

        node.name = name
        node.scale = SCNVector3Make(0.01, 0.01, 0.01)
        return node
    }

    func animateDoor(_ door: Door) {
        if !door.isAnimating {
            door.isAnimating = true
            let cb: (()->Void)? = {
                door.toogleState()
            }
            door.isOpen ? closeDoor(door, cb: cb) : openDoor(door, cb: cb)
        }
    }

    private func openDoor(_ door: Door, cb: (()->Void)? = nil) {
        var nodeToRemove: SCNNode!
        var nodeToAdd: SCNNode!
        var lastNode: SCNNode!

        switch door.name {
        case .backLeft:
            nodeToRemove = rearLeftClosed
            nodeToAdd = rearLeftOpen
            lastNode = rearLeftOpened
        case .backRight:
            nodeToRemove = rearRightClosed
            nodeToAdd = rearRightOpen
            lastNode = rearRightOpened
        case .frontLeft:
            nodeToRemove = frontLeftClosed
            nodeToAdd = frontLeftOpen
            lastNode = frontLeftOpened
        case .frontRight:
            nodeToRemove = frontRightClosed
            nodeToAdd = frontRightOpen
            lastNode = frontRightOpened
        default:
            break
        }

        let parentNode = nodeToRemove.parent!
        nodeToRemove.removeFromParentNode()
        parentNode.addChildNode(nodeToAdd)
        serialQueue.asyncAfter(deadline: .now() + 0.9) {
            parentNode.addChildNode(lastNode)
            nodeToAdd.removeFromParentNode()
            DispatchQueue.main.async {
                cb?()
            }
        }
    }

    func toogleBikeMount() {
        print("toogling bike mount")
        let opacity: CGFloat = bikeMountHidden ? 0 : 1
        bikeMountHidden = !bikeMountHidden
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .linear)
        SCNTransaction.animationDuration = 0.5
        bikeMountNodes.forEach { $0.opacity = opacity }
        SCNTransaction.commit()
    }

    private func closeDoor(_ door: Door, cb: (()->Void)? = nil) {
        var nodeToRemove: SCNNode!
        var nodeToAdd: SCNNode!
        var lastNode: SCNNode!

        switch door.name {
        case .backLeft:
            nodeToRemove = rearLeftOpened
            nodeToAdd = rearLeftClose
            lastNode = rearLeftClosed
        case .backRight:
            nodeToRemove = rearRightOpened
            nodeToAdd = rearRightClose
            lastNode = rearRightClosed
        case .frontLeft:
            nodeToRemove = frontLeftOpened
            nodeToAdd = frontLeftClose
            lastNode = frontLeftClosed
        case .frontRight:
            nodeToRemove = frontRightOpened
            nodeToAdd = frontRightClose
            lastNode = frontRightClosed
        default:
            break
        }

        let parentNode = nodeToRemove.parent!
        nodeToRemove.removeFromParentNode()
        parentNode.addChildNode(nodeToAdd)
        serialQueue.asyncAfter(deadline: .now() + 0.9) {
            parentNode.addChildNode(lastNode)
            nodeToAdd.removeFromParentNode()
            DispatchQueue.main.async {
                cb?()
            }
        }
    }
}
