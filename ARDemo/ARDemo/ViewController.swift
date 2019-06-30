//
//  ViewController.swift
//  ARDemo
//
//  Created by Leandro Demarco Vedelago on 30/06/2019.
//  Copyright © 2019 LDV. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    enum Mode: String {
        case kiaCar
        case atm
        case chair
    }

    @IBOutlet var sceneView: ARSCNView!
    private var focusSquare: FocusSquare = FocusSquare()
    let serialQueue = DispatchQueue(label: "com.igs.ARKitKia.serialSceneKitQueue")
    private var screenCenter: CGPoint!
    private var sceneBounds: CGRect = .zero
    var virtualObjectManager: VirtualObjectManager!
    private var objectAdded = false
    var currentMode: Mode = .kiaCar

    // MARK: Gestures
    let panGest = UIPanGestureRecognizer()
    var latestDragPos: CGPoint?
    let rotationGest = UIRotationGestureRecognizer()
    var latestRotationAngle: CGFloat?

    // MARK: ATM, Chair and Master nodes
    var masterNode: SCNNode?
    var atmNode: SCNNode!

    // MARK: Car nodes
    var bikeMountReactNodes: [SCNNode] = [] // Nodes that remain always visible and show back bike mount when tapped
    var bikeMountNodes: [SCNNode] = [] // Nodes that are hidden when tapped on them or one of reactive
    var bikeMountHidden = false

    var bodyNode: SCNNode!

    var rearRightClosed: SCNNode!
    var rearRightOpened: SCNNode!
    var rearRightClose: SCNNode!
    var rearRightOpen: SCNNode!

    var rearLeftClosed: SCNNode!
    var rearLeftOpened: SCNNode!
    var rearLeftClose: SCNNode!
    var rearLeftOpen: SCNNode!

    var frontRightClosed: SCNNode!
    var frontRightOpened: SCNNode!
    var frontRightClose: SCNNode!
    var frontRightOpen: SCNNode!

    var frontLeftClosed: SCNNode!
    var frontLeftOpened: SCNNode!
    var frontLeftClose: SCNNode!
    var frontLeftOpen: SCNNode!

    var frontLeftDoor = Door(name: .frontLeft)
    var frontRightDoor = Door(name: .frontRight)
    var backLeftDoor = Door(name: .backLeft)
    var backRightDoor = Door(name: .backRight)

    override func viewDidLoad() {
        super.viewDidLoad()

        virtualObjectManager = VirtualObjectManager(updateQueue: serialQueue)
        sceneBounds = sceneView.bounds
        DispatchQueue.main.async {
            self.screenCenter = self.sceneBounds.mid
        }

        // Set the view's delegate
        sceneView.delegate = self
        #if DEBUG
        //sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        #endif

        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        setupFocusSquare()
        loadATMNode()
        loadCarNodes()

        let tapGR = UITapGestureRecognizer()
        tapGR.addTarget(self, action: #selector(onTap(_:)))
        sceneView.addGestureRecognizer(tapGR)

        panGest.addTarget(self, action: #selector(onDrag(_:)))
        rotationGest.addTarget(self, action: #selector(onRotate(_:)))
        sceneView.addGestureRecognizer(panGest)
        sceneView.addGestureRecognizer(rotationGest)
    }

    var floorWorldPos: Float = 0
    @objc private func onTap(_ sender: UITapGestureRecognizer) {
        if !objectAdded {
            let viewCenter = view.bounds.mid
            let hitTestResults = sceneView.hitTest(viewCenter, types: [.existingPlaneUsingExtent])
            hitTestResults.forEach {
                print("hit test at: \($0.distance) with \($0.worldTransform.columns.3)")
            }
            if let hit = hitTestResults.first{
                floorWorldPos = hit.worldTransform.columns.3.y
                objectAdded = true
                focusSquare.hide()
                sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            }
        } else if currentMode == .kiaCar {
            let pos = sender.location(in: sceneView)
            let hitResults = performHitTestAtPosition(pos, maxRadius: 10.0, radiusInterval: 1.0)
            // Results are ordered in nearest to furthest.
            for hitRes in hitResults {
                let node = hitRes.node
                if let tappedDoor = doorBelongingToNode(node) {
                    animateDoor(tappedDoor)
                    break
                } else if bikeMountNodes.contains(node) || bikeMountReactNodes.contains(node) {
                    toogleBikeMount()
                    break
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create a session configuration and run the view's session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        config.isLightEstimationEnabled = true
        config.worldAlignment = .gravity

        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true

        sceneView.session.run(config)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        sceneBounds = sceneView.bounds

        DispatchQueue.main.async {
            self.screenCenter = self.sceneBounds.mid
        }
        updateFocusSquare()
    }

}

// MARK: Mode switching
extension ViewController {
    @IBAction func onCarTapped(sender: UIButton) {
        guard let masterNode = masterNode, currentMode != .kiaCar else { return }
        masterNode.removeAllChildNodes()
        currentMode = .kiaCar
        attachCarModel()
    }

    @IBAction func onATMTapped(sender: UIButton) {
        guard let masterNode = masterNode, currentMode != .atm else { return }
        masterNode.removeAllChildNodes()
        currentMode = .atm
        attachATMModel()
    }

    @IBAction func onChairTapped(sender: UIButton) {
        guard let masterNode = masterNode, currentMode != .chair else { return }
        masterNode.removeAllChildNodes()
        currentMode = .chair
        attachChairModel()
    }
}

// MARK: - Focus Square
extension ViewController {
    private func setupFocusSquare() {
        serialQueue.async {
            if let _ = self.focusSquare.parent {
                self.focusSquare.removeFromParentNode()
            }

            self.focusSquare = FocusSquare()
            self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
        }
    }

    private func updateFocusSquare() {
        guard !objectAdded, let screenCenter = screenCenter else { return }

        DispatchQueue.main.async {
            self.focusSquare.unhide()

            let manager = self.virtualObjectManager
            let (worldPos, planeAnchor, _) = manager!.worldPositionFromScreenPosition(
                screenCenter, in: self.sceneView, objectPos: self.focusSquare.simdPosition)

            if let worldPos = worldPos {
                self.serialQueue.async {
                    self.focusSquare.update(
                        for: worldPos, planeAnchor: planeAnchor,
                        camera: self.sceneView.session.currentFrame?.camera)
                }
                //self.textManager.cancelScheduledMessage(forType: .focusSquare)
            }
        }
    }
}

// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        updateFocusSquare()

        // Light estimate
        if let estimate = sceneView.session.currentFrame?.lightEstimate {
            // A value of 1000 is considered neutral lighting enviroment intensity normalizes
            // 1.0 to neutral so we need to scale the ambientIntensity value
            let intensity = estimate.ambientIntensity / 1000.0
            sceneView.scene.lightingEnvironment.intensity = intensity
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let _ = anchor as? ARPlaneAnchor {
            // Do nothing for detected planes
        } else {
            masterNode = node
            switch currentMode {
            case .kiaCar: attachCarModel()
            case .atm: attachATMModel()
            case .chair: attachChairModel()
            }
        }
    }

    private func attachCarModel() {
        guard let masterNode = masterNode else { return }
        masterNode.addChildNode(bodyNode)
        masterNode.addChildNode(frontLeftClosed)
        masterNode.addChildNode(frontRightClosed)
        masterNode.addChildNode(rearRightClosed)
        masterNode.addChildNode(rearLeftClosed)

        masterNode.worldPosition.y = floorWorldPos + masterNode.size().y / 2
        let deltaY: Float = -0.02725
        let allNodes: [SCNNode] = [bodyNode, frontLeftClosed, frontLeftOpened, frontLeftOpen, frontLeftClose,
                                   frontRightClosed, frontRightOpened, frontRightOpen, frontRightClose,
                                   rearLeftClosed, rearLeftOpened, rearLeftOpen, rearLeftClose,
                                   rearRightClosed, rearRightOpened, rearRightOpen, rearRightClose]

        for node in allNodes {
            node.worldPosition.y += deltaY
        }
    }

    private func attachATMModel() {
        guard let masterNode = masterNode else { return }
        masterNode.addChildNode(atmNode)
    }

    private func attachChairModel() {
        guard let masterNode = masterNode else { return }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user

    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay

    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required

    }
}
