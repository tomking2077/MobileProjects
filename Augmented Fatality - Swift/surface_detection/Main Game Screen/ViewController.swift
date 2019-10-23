//
//  ViewController.swift
//  surface_detection
//
//  Created by jacobmiddleton15 on 2/17/19.
//  Copyright © 2019 jacobmiddleton15. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import MultipeerConnectivity



class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var testLabel: UILabel!
    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var gameOverView: UIView!
    @IBOutlet weak var gameOverLabel: UILabel!
    @IBOutlet weak var restart: UIButton!
    @IBOutlet weak var sendMapButton: UIButton!
    @IBOutlet weak var mappingStatusLabel: UILabel!
    @IBOutlet weak var devMode: UISwitch!
    @IBOutlet weak var confirmOutlineButton: UIButton!
    @IBOutlet weak var onScreenDebugText: UITextView!
    
    var gameBoardIsPlaced = false
    var boardOutlineIsPlaced = false
    var tileLength = Float(0.05)
    var minHeight = Float(0.00)
    var anchor = SCNVector3(0.0, 0.0, 0.0)
    let tileNum = 7
    var boardTiles: [[SCNNode]] = []
    var heightDataArray: [[HeightData]] = []
    var anchorNode = SCNNode()
    var boardOutlineNode = SCNNode()
    
    var highlightedTiles:[SCNNode] = []
    
    var gameNotStarted = true
    var drawBoard = true
    var arAnchorSet = false
    var globalTransform = simd_float4x4()
    
    var animations = [String: CAAnimation]()
    
    var heroIdle:Bool = true
    var heroAniNode = SCNNode()
    lazy var hero = (node: heroAniNode, currentTile: (x: 0, z: 0))
    
    var goblinIdle:Bool = true
    var goblinAniNode = SCNNode()
    lazy var goblin = (node: goblinAniNode, currentTile: (x: 0, z: 0))
    
    var multipeerSession: MultipeerSession!
    var SHOW_ON_SCREEN_DEBUG_TEXT = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        //let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        //Screen Gestures
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateNode(_:)))
        sceneView.addGestureRecognizer(rotateGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(scaleNode(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panNode(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(recognizer:) ))
        longPressGesture.minimumPressDuration = 0.1
        longPressGesture.numberOfTouchesRequired = 1;
        longPressGesture.allowableMovement = 10;
        sceneView.addGestureRecognizer(longPressGesture)
        
        // Set the scene to the view
        //sceneView.scene = scene
        
        //testLabel?.text = "hello"
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData)
        multipeerSession?.delegate = self
        
        
        //BattleActions
        defaultHide()
        //setupStatusBars()
        devMode.setOn(false, animated: true)
        
        //let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(swipe:)))
        //leftSwipe.direction = UISwipeGestureRecognizer.Direction.left
        //self.view.addGestureRecognizer(leftSwipe)
        //End of BattleActions
        
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        // Start the view's AR session.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self as? ARSessionDelegate
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // Long press variables
    var isLongPressing = false
    
    @objc func handleLongPress(recognizer:UILongPressGestureRecognizer) {
        
        if gameBoardIsPlaced && drawBoard {
            isLongPressing = true
            
            //print("LongPress called")
            let configuration = ARWorldTrackingConfiguration()
            sceneView.session.run(configuration)
            let location = recognizer.location(in: sceneView)
            //guard let hitTestResult = sceneView.hitTest(location, types: .existingPlane).first else { return }
            guard let hitTestResult = sceneView.hitTest(location, types: [ARHitTestResult.ResultType.featurePoint]).first else { return }
            let currentPosition = SCNVector3Make(hitTestResult.worldTransform.columns.3.x,
                                                 hitTestResult.worldTransform.columns.3.y,
                                                 hitTestResult.worldTransform.columns.3.z)
            
            adjustHeight(touchVector: currentPosition, anchorPoint: mainAnchorPoint)
            
            isLongPressing = false
        }
        if(multipeerSession.connectedPeers == [] && !devMode.isOn){
            updateSessionInfoLabel(for: sceneView.session.currentFrame!, state: "waitingForPeer")
            //0x280982400 -> sample PeerID for devmode
        }
        /*else{
         let configuration = ARWorldTrackingConfiguration()
         sceneView.session.run(configuration)
         let location = recognizer.location(in: sceneView)
         //guard let hitTestResult = sceneView.hitTest(location, types: .existingPlane).first else { return }
         guard let hitTestResult = sceneView.hitTest(location, types: [ARHitTestResult.ResultType.featurePoint]).first else { return }
         let currentPosition = SCNVector3Make(hitTestResult.worldTransform.columns.3.x,
         hitTestResult.worldTransform.columns.3.y,
         hitTestResult.worldTransform.columns.3.z)
         
         adjustHeight(touchVector: currentPosition, anchorPoint: mainAnchorPoint)
         }*/
    }
    
    func loadCharacter(parent: SCNNode) {
        
        if(parent == hero.node)
        {
            loadIdle(idleFile: "art.scnassets/base-magicIdle.dae", folderName: "base", parent: parent)
            
            loadAnimation(key: "hero-attack", sceneName: "art.scnassets/base-magicSmite", animationIdentifier: "base-magicSmite-1")
            
            loadAnimation(key: "hero-move", sceneName: "art.scnassets/base-magicWalk", animationIdentifier: "base-magicWalk-1")
            
            loadAnimation(key: "hero-teleport1", sceneName: "art.scnassets/base-teleport1", animationIdentifier: "base-teleport1-1")
            
            loadAnimation(key: "hero-teleport2", sceneName: "art.scnassets/base-teleport2", animationIdentifier: "base-teleport2-1")
        }
        else
        {
            loadIdle(idleFile: "art.scnassets/base-goblinIdle.dae", folderName: "base", parent: parent)
            
            loadAnimation(key: "goblin-move", sceneName: "art.scnassets/base-goblinWalk", animationIdentifier: "base-goblinWalk-1")
            
            loadAnimation(key: "goblin-swipe", sceneName: "art.scnassets/base-goblinSwipe", animationIdentifier: "base-goblinSwipe-1")
        }
    }
    
    func loadIdle(idleFile: String, folderName: String, parent: SCNNode) {
        let Idle = SCNScene(named: idleFile)!
        var nodeIdle:SCNNode!
        
        nodeIdle = Idle.rootNode.childNode(withName: folderName, recursively: true)
        
        parent.addChildNode(nodeIdle)
        
        //properly place based on host status and character type; your character is always hero; host at [3][6]
        var tile:SCNNode!
        if multipeerSession.host == multipeerSession.myPeerID
        {
            if parent == hero.node
            {
                tile = boardTiles[3][6]
                hero.currentTile.x = 3
                hero.currentTile.z = 6
            }
            else
            {
                tile = boardTiles[3][0]
                goblin.currentTile.x = 3
                goblin.currentTile.z = 0
            }
        }
        else
        {
            if parent == hero.node
            {
                tile = boardTiles[3][0]
                hero.currentTile.x = 3
                hero.currentTile.z = 0
            }
            else
            {
                tile = boardTiles[3][6]
                goblin.currentTile.x = 3
                goblin.currentTile.z = 6
            }
        }
        
        //rotate properly to face opponent; 180 degrees
        if tile == boardTiles[3][6]
        {
            parent.rotation = SCNVector4(0, 1, 0, Float.pi)
        }
        
        //positions and scales
        parent.position = tile.position
        parent.scale = SCNVector3(tileLength*0.11, tileLength*0.11, tileLength*0.11)
        parent.castsShadow = true
        sceneView.scene.rootNode.addChildNode(parent)
    }
    
    func loadAnimation(key: String, sceneName: String, animationIdentifier: String) {
        let sceneURL = Bundle.main.url(forResource: sceneName, withExtension: "dae")
        let sceneSource = SCNSceneSource(url: sceneURL!, options: nil)
        
        if let animationObject = sceneSource?.entryWithIdentifier(animationIdentifier, withClass: CAAnimation.self) {
            // The animation will only play once
            animationObject.repeatCount = 1
            // To create smooth transitions between animations
            animationObject.fadeInDuration = CGFloat(1)
            animationObject.fadeOutDuration = CGFloat(0.5)
            
            // Store the animation for later use
            animations[key] = animationObject
        }
    }
    
    func playAnimation(key: String, parent: SCNNode) {
        parent.addAnimation(animations[key]!, forKey: key)
    }
    
    func stopAnimation(key: String, parent: SCNNode) {
        parent.removeAnimation(forKey: key, blendOutDuration: CGFloat(0.5))
    }
    
    func animateMove(newTile: SCNNode, parent: SCNNode) {
        if(parent == hero.node) //hero wizard man
        {
            if(abs((newTile.position.y - parent.position.y)) <= 0.025)
            {
                playAnimation(key: "hero-move", parent: parent)
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 1.5
                parent.position = SCNVector3Make(newTile.position.x, ((newTile.position.y - anchor.y) * 2) + anchor.y, newTile.position.z)
                SCNTransaction.commit()
            }
            else
            {
                playAnimation(key: "hero-teleport1", parent: parent)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {parent.position = SCNVector3Make(newTile.position.x, ((newTile.position.y - self.anchor.y) * 2) + self.anchor.y, newTile.position.z)})
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {self.playAnimation(key: "hero-teleport2", parent: parent)})
            }
        }
        else //goblin man
        {
            if(abs((newTile.position.y - parent.position.y)) <= 0.1)
            {
                playAnimation(key: "goblin-move", parent: parent)
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 1.5
                parent.position = SCNVector3Make(newTile.position.x, ((newTile.position.y - anchor.y) * 2) + anchor.y, newTile.position.z)
                SCNTransaction.commit()
            }
            else if((newTile.position.y - parent.position.y) > 0)
            {
                //placeholder
                playAnimation(key: "goblin-move", parent: parent)
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 1.5
                parent.position = SCNVector3Make(newTile.position.x, ((newTile.position.y - anchor.y) * 2) + anchor.y, newTile.position.z)
                SCNTransaction.commit()
            }
            else if((newTile.position.y - parent.position.y) < 0)
            {
                //placeholder
                playAnimation(key: "goblin-move", parent: parent)
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 1.5
                parent.position = SCNVector3Make(newTile.position.x, ((newTile.position.y - anchor.y) * 2) + anchor.y, newTile.position.z)
                SCNTransaction.commit()
            }
        }
        for i in 0...6
        {
            for j in 0...6
            {
                if(boardTiles[i][j] == newTile)
                {
                    if(parent == hero.node)
                    {
                        hero.currentTile.x = i
                        hero.currentTile.z = j
                    }
                    else
                    {
                        goblin.currentTile.x = i
                        goblin.currentTile.z = j
                    }
                }
            }
        }
    }

    func generateParticles(_for: String, tiles: [SCNNode], damage: Int) {
        var particles:SCNParticleSystem!
        
        if _for == "hero"
        {
            particles = SCNParticleSystem(named: "hero-attackEffects", inDirectory: nil)!
        }
        else if _for == "goblin"
        {
            particles = SCNParticleSystem(named: "goblin-attackEffects", inDirectory: nil)!
        }
        
        for i in 0...tiles.count - 1
        {
            //since boardTiles are immutable, and I need to raise y slightly, i create new node in same place
            if tiles[i] != boardTiles[hero.currentTile.x][hero.currentTile.z]
            {
                let temp = SCNNode()
                temp.position = SCNVector3Make(tiles[i].position.x,
                                               ((tiles[i].position.y - anchor.y) * 2) + anchor.y + (tileLength),
                                               tiles[i].position.z)
                particles.particleSize = CGFloat(tileLength/60)
                particles.particleSizeVariation = CGFloat(tileLength * 5)
                particles.emitterShape = SCNBox(width: CGFloat(tileLength), height: CGFloat(tileLength), length: CGFloat(tileLength), chamferRadius: 0)
                particles.birthRate = CGFloat((damage * damage)/2)
                temp.addParticleSystem(particles)
                sceneView.scene.rootNode.addChildNode(temp)
            }
        }
    }
    
    var mainAnchorPoint: SCNVector3 = SCNVector3Make(0, 0, 0)
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(devMode.isOn){
            multipeerSession.host = multipeerSession.myPeerID
        }
        if(multipeerSession.connectedPeers == [] && !devMode.isOn){
            updateSessionInfoLabel(for: sceneView.session.currentFrame!, state: "waitingForPeer")
            //0x280982400 -> sample PeerID for devmode
        }
        else if(multipeerSession.myID != multipeerSession.sessionHost && gameNotStarted && !devMode.isOn){
            DispatchQueue.main.async {
                UIApplication.shared.beginIgnoringInteractionEvents()
            }
        }
        else{
            guard let touch = touches.first else { return }
            let result = sceneView.hitTest(touch.location(in: sceneView), types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])
            guard let hitResult = result.last else { return }
            
            globalTransform = hitResult.worldTransform
            let hitTransform = SCNMatrix4(hitResult.worldTransform)
            let hitVector = SCNVector3Make(hitTransform.m41, hitTransform.m42, hitTransform.m43)
            //print("hitVector = \(hitVector)")
            
            if !boardOutlineIsPlaced && !gameBoardIsPlaced && !arAnchorSet {
                mainAnchorPoint = hitVector
                anchor = hitVector
                boardOutlineNode = createTile(position: anchor, anchorPoint: mainAnchorPoint)
                sceneView.scene.rootNode.addChildNode(boardOutlineNode)
                boardOutlineIsPlaced = true
                self.confirmOutlineButton.isHidden = false
            }
            else if !boardOutlineIsPlaced && gameBoardIsPlaced {
                arAnchorSet = true
            }
            else if gameBoardIsPlaced && arAnchorSet && gameNotStarted {
                //adjustHeight(touchVector: hitVector, anchorPoint: mainAnchorPoint)
            }
        }
    }
    
    func setHeightDataArray(anchorPos: SCNVector3) {
        
        for x in 0..<tileNum{
            var heightColArray: [HeightData] = []
            for z in 0..<tileNum{
                var heightData: HeightData = HeightData(curVal: anchorPos.y)
                heightColArray.append(heightData)
            }
            heightDataArray.append(heightColArray)
        }
    }
    
    func createGameBoard(anchorPos: SCNVector3) {
        //anchorNode = createSphere(position: anchorPos)
        sceneView.scene.rootNode.addChildNode(anchorNode)
        
        //showAnchor(position: anchorPos)     // For debugging purposes
        var tilePos = anchorPos
        tilePos.x -= (tileLength * Float(4))
        tilePos.z -= (tileLength * Float(4))
        
        //Column first order
        
        for x in 0..<tileNum {
            tilePos.x += tileLength
            
            //Column array
            var tileColArray: [SCNNode] = []
            
            for z in 0..<tileNum {
                tilePos.z += tileLength
                tilePos.y = heightDataArray[x][z].curVal
                tileColArray.append(createBox(position: tilePos, anchorPoint: anchorPos))
            }
            
            tilePos.z -= tileLength * Float(tileNum)
            
            boardTiles.append(tileColArray)
        }
        
        loadCharacter(parent: hero.node)
        loadCharacter(parent: goblin.node)
    
        
        placeTiles(tiles: boardTiles)
    }
    
    
    
    func createTile(position: SCNVector3, anchorPoint: SCNVector3)-> SCNNode {
        let tileNode = SCNNode()
        let tileMat = SCNMaterial()
        tileMat.diffuse.contents = UIImage(named: "art.scnassets/tileMat.png")
        
        
        if !boardOutlineIsPlaced && !gameBoardIsPlaced {
            let tileShape = SCNPlane(width: CGFloat(tileLength * Float(7.0)), height: CGFloat(tileLength * Float(7.0)) )
            tileNode.geometry = tileShape
            
            tileShape.materials = [tileMat]
            
            // Set tile position
            tileNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)     // SCNPlanes are vertical by default, so rotate
            tileNode.position = position
        }
        else if boardOutlineIsPlaced && !gameBoardIsPlaced && !arAnchorSet {
            // Define tile properties
            let tileShape = SCNPlane(width: CGFloat(tileLength), height: CGFloat(tileLength) )
            tileNode.geometry = tileShape
            
            tileShape.materials = [tileMat]
            
            // Set tile position
            tileNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)     // SCNPlanes are vertical by default, so rotate
            tileNode.position = position                                            // and return to hit test position.
        }
        /*else if arAnchorSet {
            var boxHeight = anchorPoint.y
            tileNode.position = position
            if position.y > anchorPoint.y {
                boxHeight = position.y - anchorPoint.y                    // Difference between Y value of hit test and gameboard anchor.
                tileNode.position.y = position.y - (boxHeight / 2)  // Position is center of SCNNode object (center of box).
            }
            else if position.y < anchorPoint.y {
                boxHeight = anchorPoint.y - position.y                    // Difference between Y value of hit test and gameboard anchor.
                tileNode.position.y = position.y + (boxHeight / 2)  // Offset SCNNode Y value so that it remains connected to game board.
            }
            
            let tileShape = SCNBox(width: CGFloat(tileLength), height: CGFloat(boxHeight), length: CGFloat(tileLength), chamferRadius: 0.0)
            tileNode.geometry = tileShape
            
            tileShape.materials = [tileMat]
        }*/
        
        
        
        /*if position.y > anchorPoint.y {
            var boxHeight = anchorPoint.y
            tileNode.position = position
            
            boxHeight = position.y - anchorPoint.y                    // Difference between Y value of hit test and gameboard anchor.
            tileNode.position.y = position.y - (boxHeight / 2)  // Position is center of SCNNode object (center of box).
            
            let tileShape = SCNBox(width: CGFloat(tileLength), height: CGFloat(boxHeight), length: CGFloat(tileLength), chamferRadius: 0.0)
            tileNode.geometry = tileShape
            
            tileShape.materials = [tileMat]
        }
        else if position.y < anchorPoint.y {
            var boxHeight = anchorPoint.y
            tileNode.position = position
            
            boxHeight = anchorPoint.y - position.y                    // Difference between Y value of hit test and gameboard anchor.
            tileNode.position.y = position.y + (boxHeight / 2)  // Offset SCNNode Y value so that it remains connected to game board.
            
            let tileShape = SCNBox(width: CGFloat(tileLength), height: CGFloat(boxHeight), length: CGFloat(tileLength), chamferRadius: 0.0)
            tileNode.geometry = tileShape
            
            tileShape.materials = [tileMat]
        }*/
        
        return tileNode
    }
    
    func createBox(position: SCNVector3, anchorPoint: SCNVector3)-> SCNNode {
        
        let boxNode = SCNNode()
        let tileMat = SCNMaterial()
        tileMat.diffuse.contents = UIImage(named: "art.scnassets/tileMat.png")
        
        var boxHeight = anchorPoint.y
        boxNode.position = position
        if position.y > anchorPoint.y {
            boxHeight = position.y - anchorPoint.y                    // Difference between Y value of hit test and gameboard anchor.
            boxNode.position.y = position.y - (boxHeight / 2)  // Position is center of SCNNode object (center of box).
        }
        else if position.y < anchorPoint.y {
            boxHeight = anchorPoint.y - position.y                    // Difference between Y value of hit test and gameboard anchor.
            boxNode.position.y = position.y + (boxHeight / 2)  // Offset SCNNode Y value so that it remains connected to game board.
        }else{
            boxHeight = 0.05
        }
        
        let boxShape = SCNBox(width: CGFloat(tileLength), height: CGFloat(boxHeight), length: CGFloat(tileLength), chamferRadius: 0.0)
        boxNode.geometry = boxShape
        
        boxShape.materials = [tileMat]
        
        return boxNode
    }
    
    func placeTiles(tiles: [[SCNNode]]){
        for i in 0..<tileNum {
            for j in 0..<tileNum {
                sceneView.scene.rootNode.addChildNode(tiles[i][j])
                
            }
        }
        
    }
    
    func updateGSHeightArray() {
        
        //tilePos.y = anchor.y - heightDataArray[indexX][indexZ].curVal
        
        for heightIndexX in 0..<tileNum {
            for heightIndexZ in 0..<tileNum {
                gameState.board.array[heightIndexX][heightIndexZ].height = heightDataArray[heightIndexX][heightIndexZ].curVal
                //attack.heightArray[heightIndexX][heightIndexZ] += Float(20)
            }
        }
    }
    
    func updateLocalHeightArray(recvState: GameSimpleState) {
        for x in 0..<tileNum {
            for z in 0..<tileNum {
                heightDataArray[x][z].curVal = recvState.heightArray[x][z]
                //heightDataArray[x][z].curVal = gameState.board.array[heightIndexX][heightIndexZ].height
                //attack.heightArray[heightIndexX][heightIndexZ] += Float(20)
            }
        }
    }
    
    func createSphere(position: SCNVector3) -> SCNNode {
        let sphereNode = SCNNode()
        let sphereShape = SCNSphere(radius: CGFloat(tileLength / 6.0))
        
        let sphereMat = SCNMaterial()
        sphereMat.diffuse.contents = UIColor.green
        sphereShape.materials = [sphereMat]
        
        sphereNode.geometry = sphereShape
        sphereNode.position = position
        
        return sphereNode
    }
    
    func adjustHeight(touchVector: SCNVector3, anchorPoint: SCNVector3){
        //adjust character height
        if(gameNotStarted){
            
        
            hero.node.position =
                SCNVector3Make(boardTiles[hero.currentTile.x][hero.currentTile.z].position.x,
                               ((boardTiles[hero.currentTile.x][hero.currentTile.z].position.y - anchor.y) * 2) + anchor.y,
                               boardTiles[hero.currentTile.x][hero.currentTile.z].position.z)
            
            goblin.node.position =
                SCNVector3Make(boardTiles[goblin.currentTile.x][goblin.currentTile.z].position.x,
                               ((boardTiles[goblin.currentTile.x][goblin.currentTile.z].position.y - anchor.y) * 2) + anchor.y ,
                               boardTiles[goblin.currentTile.x][goblin.currentTile.z].position.z)
            
            let topLeftTile = boardTiles.first!.first!.simdWorldPosition
            let botRightTile = boardTiles.last!.last!.simdWorldPosition
            let xMin = topLeftTile.x;
            let xMax = botRightTile.x;
            let zMin = topLeftTile.z;
            let zMax = botRightTile.z;
            
            //Out of bounds
            if( !isWithin(a: xMin, b: xMax, num: touchVector.x) ||
                !isWithin(a: zMin, b: zMax, num: touchVector.z)){
                return;
            }
            
            var minX = Float(1)
            var minZ = Float(1)
            var indexZ = -1
            var indexX = -1
            var mappedX = Float(0.5)
            var mappedZ = Float(0.5)
            
            
            
            for j in 0..<tileNum{
                if( abs(touchVector.x - boardTiles[j].first!.simdWorldPosition.x) < minX ){
                    minX = abs(touchVector.x - boardTiles[j].first!.simdWorldPosition.x)
                    indexX = j
                    mappedX = boardTiles[j].first!.simdWorldPosition.x
                }
            }
            
            let myCol = boardTiles[indexX]
            
            for i in 0..<tileNum{
                if( abs(touchVector.z - myCol[i].simdWorldPosition.z) < minZ ){
                    minZ = abs(touchVector.z - myCol[i].simdWorldPosition.z)
                    indexZ = i
                    mappedZ = myCol[i].simdWorldPosition.z
                }
            }
            
            let oldTile = boardTiles[indexX][indexZ]
            
            //Error Out of bounds
            if(minX == -1 || minZ == -1){
                return
            }
            else if( abs(oldTile.simdWorldPosition.y - touchVector.y) <= minHeight ){
                return
            }
            else{
                heightDataArray[indexX][indexZ].addVal(newVal: touchVector.y)
                let newY = heightDataArray[indexX][indexZ].curVal
                let newTile = SCNVector3(mappedX, newY, mappedZ)
                let fnewTile = createBox(position: newTile, anchorPoint: anchorPoint)
                //sceneView.scene.rootNode.addChildNode(fnewTile)
                sceneView.scene.rootNode.replaceChildNode(oldTile, with: fnewTile)
                boardTiles[indexX][indexZ] = fnewTile
            }
        }
    }
    
    func isWithin(a: Float, b: Float, num: Float) -> Bool{
        var test = false;
        if( num >= a && num <= b){
            test = true;
        }
        return test;
    }
    
    // Rotation variables
    var currentAngleY = Float(0.0)
    var isRotating = false
    
    @objc func rotateNode(_ gesture: UIRotationGestureRecognizer) {
        if !gameBoardIsPlaced {
            // Get current rotation angle
            let rotation = Float(gesture.rotation)
            
            // Rotate node
            if(gesture.state == .changed) {
                isRotating = true
                //boardTiles[0][0].eulerAngles.y = currentAngleY + rotation
                /*for i in 0...7 {
                 for j in 0...7 {
                 boardTiles[i][j].eulerAngles.y = currYAngles[i][j] + rotation
                 //boardTiles[i][j].rotation = SCNMatrix4(anchor.x, anchor.y, anchor.z, rotation)
                 }
                 }*/
                boardOutlineNode.eulerAngles.y = currentAngleY + rotation
            }
            
            // Update current rotation angle
            if(gesture.state == .ended) {
                //currentAngleY = boardTiles[0][0].eulerAngles.y
                /*for i in 0...7 {
                 for j in 0...7 {
                 currYAngles[i][j] = boardTiles[i][j].eulerAngles.y
                 }
                 }*/
                //currentAngleY = anchorNode.eulerAngles.y
                currentAngleY = boardOutlineNode.eulerAngles.y
                isRotating = false
            }
        }
    }
    
    // Scale variables
    var isScaling = false
    
    @objc func scaleNode(_ gesture: UIPinchGestureRecognizer) {
        if !gameBoardIsPlaced {
            //let scale = Float(gesture.scale)
            
            if(gesture.state == .changed) {
                isScaling = true
                let scale = Float(gesture.scale) * Float(boardOutlineNode.scale.x)
                
                boardOutlineNode.scale = SCNVector3Make(scale, scale, scale)
                
                gesture.scale = 1
            }
            else if(gesture.state == .ended) {
                isScaling = false
            }
        }
    }
    
    // Pan variables
    var isPanning = false
    
    @objc func panNode(_ gesture: UIPanGestureRecognizer) {
        if !gameBoardIsPlaced {
            
            if(gesture.state == .changed) {
                isPanning = true
                
                let results = self.sceneView.hitTest(gesture.location(in: gesture.view), types: ARHitTestResult.ResultType.featurePoint)
                guard let result: ARHitTestResult = results.first else {
                    return
                }
                
                let position = SCNVector3Make(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
                boardOutlineNode.position = position
                anchor = position
                mainAnchorPoint = position
            }
            else if (gesture.state == .ended) {
                isPanning = false
            }
        }
    }
    
    @IBAction func confirmBoardOutline(_ sender: UIButton?) {
        tileLength *= boardOutlineNode.scale.x
        boardOutlineNode.removeFromParentNode()
        
        setHeightDataArray(anchorPos: mainAnchorPoint)
        createGameBoard(anchorPos: anchor)
        boardOutlineIsPlaced = false
        gameBoardIsPlaced = true
        self.sendMapButton.isHidden = false
        
        let anchorSend = ARAnchor(name: "board", transform: globalTransform)
        sceneView.session.add(anchor: anchorSend)
        updateSessionInfoLabel(for: sceneView.session.currentFrame!, state: "boardSet")
        
        /*
         // Send the anchor info to peers, so they can place the same content.
         if !devMode.isOn {
         updateSessionInfoLabel(for: sceneView.session.currentFrame!, state: "boardSet")
         guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchorSend, requiringSecureCoding: true)
         else { fatalError("can't encode anchor") }
         self.multipeerSession.sendToAllPeers(data)
         }
         */
        
        DispatchQueue.main.async {
            self.confirmOutlineButton.isHidden = true
            self.sendMapButton.isHidden = false
        }
    }
    
    func create2DFArray(heights: [[HeightData]]) -> [[Float]] {
        var curHeight: Float
        var ffArray: [[Float]] = []
        
        for i in 0..<heights.count{
            
            var fArray: [Float] = []
            for j in 0..<heights[i].count{
                
                curHeight = -(anchor.y - heights[i][j].curVal)
                
                //Only for testing
                //curHeight += 0.4
                
                fArray.append(curHeight)
            }
            ffArray.append(fArray)
        }
        return ffArray
    }
    
    
    var mapProvider: MCPeerID?
    
    /// - Tag: ReceiveData
    func receivedData(_ data: Data, from peer: MCPeerID) {
        
        do {
            NSKeyedUnarchiver.setClass(GameSimpleState.self, forClassName: "GameSimpleState")
            if let newGameState = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data as Data) as? GameSimpleState{
                var prevHealth = Int()
                if multipeerSession.host == multipeerSession.myPeerID
                {
                    prevHealth = gameState.characters[0].health
                }
                else
                {
                    prevHealth = gameState.characters[1].health
                }
                
                gameState.unpackage(gameSimpleState: newGameState)
                
                if(gameNotStarted){
                    print("I AM HERE!!!!!!!!!!!!!!!!!!!!!!!!1")
                    
                    //Change local array
                    
                    updateLocalHeightArray(recvState: newGameState)
                    
                    //Removing old nodes
                    for x in 0..<tileNum{
                        for z in 0..<tileNum{
                            boardTiles[x][z].removeFromParentNode()
                        }
                    }
                    
                    boardTiles = []
                    
                    arAnchorSet = true
                    gameBoardIsPlaced = true
    
                    //Recreating Board
                    //DispatchQueue.main.asyncAfter(deadline: .now() + 1.75, execute: {
                        createGameBoard(anchorPos: self.mainAnchorPoint)
                        
                    //})
                }
                
                attackRecieved(prevHealth: prevHealth, sceneView.session)
                gameNotStarted = false
                
            }
            else if let worldMap = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? ARWorldMap{
                // Run the session with the received world map.
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.initialWorldMap = worldMap
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                // Remember who provided the map for showing UI feedback.
                mapProvider = peer
                boardOutlineIsPlaced = true
                arAnchorSet = false
                gameBoardIsPlaced = false
                for a in worldMap.anchors {
                    if let name = a.name, name.hasPrefix("board") && drawBoard{
                        let vector = SCNVector3Make(a.transform.translation.x, a.transform.translation.y, a.transform.translation.z)
                        mainAnchorPoint = vector
                        setHeightDataArray(anchorPos: vector)
                        createGameBoard(anchorPos: vector)
                    }
                }
                drawBoard = false
                updateSessionInfoLabel(for: sceneView.session.currentFrame!, state: "gameStart")
                
            }
                
            else {
                
                print("unknown data recieved from \(peer)")
            }
            
        } catch {
            print("can't decode data recieved from \(peer)")
        }
    }
    
    // MARK: - AR session management
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty && multipeerSession.connectedPeers.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move around to map the environment, or wait to join a shared session."
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing) where mapProvider != nil,
             .limited(.relocalizing) where mapProvider != nil:
            message = "Received map from \(mapProvider!.displayName)."
            
        case .limited(.relocalizing):
            message = "Resuming session — move to where you were when the session was interrupted."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }
        
        DispatchQueue.main.async {
            self.sessionInfoLabel.text = message
            self.sessionInfoView.isHidden = message.isEmpty
        }
    }
    
    @IBAction func resetTracking(_ sender: UIButton?) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    /// - Tag: CheckMappingStatus
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        switch frame.worldMappingStatus {
        case .notAvailable, .limited:
            sendMapButton.isEnabled = false
        case .extending:
            sendMapButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
        case .mapped:
            sendMapButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
        }
        mappingStatusLabel.text = frame.worldMappingStatus.description
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking(nil)
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    //-------BattleActions -------
    
    
    let MOVE_DESCRIPTIONS = ["Attack 1", "Up", "Attack 2", "Left", "Basic Attack", "Right", "Attack 3", "Down", "Attack 4"]
    let CENTER_MOVE = 4
    
    let MAX_HEALTH = 100
    let MAX_ENERGY = 20
    
    var gameState = GameState()
    
    var moveIndex1 = -1
    var moveIndex2 = -1
    var curMovePart = 1
    
    @IBOutlet weak var pressConfirm:UIButton?
    @IBOutlet weak var pressBack:UIButton?
    
    @IBOutlet weak var upArrow:UIButton?
    @IBOutlet weak var leftArrow:UIButton?
    @IBOutlet weak var rightArrow:UIButton?
    @IBOutlet weak var downArrow:UIButton?
    @IBOutlet weak var centerArrow:UIButton?
    @IBOutlet weak var attackBasic:UIButton?
    @IBOutlet weak var attack1:UIButton?
    @IBOutlet weak var attack2:UIButton?
    @IBOutlet weak var attack3:UIButton?
    @IBOutlet weak var attack4:UIButton?
    
    @IBOutlet weak var move:UIButton?
    @IBOutlet weak var players:UIButton?
    @IBOutlet weak var attacks:UIButton?
    @IBOutlet weak var menu:UIButton?
    
    @IBOutlet weak var pHealthBar:UIProgressView!
    @IBOutlet weak var pEnergyBar:UIProgressView!
    @IBOutlet weak var eHealthBar:UIProgressView!
    @IBOutlet weak var eEnergyBar:UIProgressView!
    @IBOutlet weak var currentImage:UIImageView!
    
    //dummy vals, won't let me create otherwise
    var pHP = MetricBar(maxVal: 0, curVal: 0)
    var pEP = MetricBar(maxVal: 0, curVal: 0)
    var eHP = MetricBar(maxVal: 0, curVal: 0)
    var eEP = MetricBar(maxVal: 0, curVal: 0)
    let bog = UIImage(named: "bog.jpg")
    let sminem = UIImage(named: "sminem.jpg")
    var playerTurn = Bool(true)
    
    
    @IBAction func pressConfirm(_ sender: Any) {
        updateCurMovePart(value: 4)
        unhighlightTiles()
        updateHealthVisual()
    }
    
    @IBAction func pressBack(_ sender: Any) {
        updateSessionInfoLabel(for: sceneView.session.currentFrame!, state: "blank")
        updateCurMovePart(value: curMovePart - 1)
        unhighlightTiles()
    }
    
    @IBAction func pressMove(_ sender: Any) {
        updateSessionInfoLabel(for: sceneView.session.currentFrame!, state: "blank")
        updateCurMovePart(value: 1)
    }
    
    @IBAction func pressMenu(_ sender: Any) {
        updateSessionInfoLabel(for: sceneView.session.currentFrame!, state: "blank")
    }
    
    @IBAction func pressPlayerInfo(_ sender: Any) {
        updateSessionInfoLabel(for: sceneView.session.currentFrame!, state: "characterInfo")
    }
    
    @IBAction func pressAttackInfo(_ sender: Any) {
        updateSessionInfoLabel(for: sceneView.session.currentFrame!, state: "attackInfo")
    }
    
    @IBAction func pressAttack1(_ sender: Any) {
        setMoveIndex(index: 0)
    }
    
    @IBAction func pressUp(_ sender: Any) {
        setMoveIndex(index: 1)
    }
    
    @IBAction func pressAttack2(_ sender: Any) {
        setMoveIndex(index: 2)
    }
    
    @IBAction func pressLeft(_ sender: Any) {
        setMoveIndex(index: 3)
    }
    
    @IBAction func pressCenter(_ sender: Any) {
        setMoveIndex(index: 4)
    }
    
    @IBAction func pressRight(_ sender: Any) {
        setMoveIndex(index: 5)
    }
    
    @IBAction func pressAttack3(_ sender: Any) {
        setMoveIndex(index: 6)
    }
    
    @IBAction func pressDown(_ sender: Any) {
        setMoveIndex(index: 7)
    }
    
    @IBAction func pressAttack4(_ sender: Any) {
        setMoveIndex(index: 8)
    }
    
    
    func hideMovementButtons(value: Bool){
        DispatchQueue.main.async {
            self.upArrow?.isHidden = value
            self.leftArrow?.isHidden = value
            self.rightArrow?.isHidden = value
            self.downArrow?.isHidden = value
            self.centerArrow?.isHidden = value
        }
    }
    
    func hideAttackButtons(value: Bool){
        DispatchQueue.main.async {
            if (value){
                self.attack1?.isHidden = true
                self.attack2?.isHidden = true
                self.attack3?.isHidden = true
                self.attack4?.isHidden = true
                self.attackBasic?.isHidden = true
            }
            else {
                self.attack1?.isHidden = !self.gameState.isAttackLegal(charIndex: self.getCharacterIndex(), attackIndex: 1)
                self.attack2?.isHidden = !self.gameState.isAttackLegal(charIndex: self.getCharacterIndex(), attackIndex: 2)
                self.attack3?.isHidden = !self.gameState.isAttackLegal(charIndex: self.getCharacterIndex(), attackIndex: 3)
                self.attack4?.isHidden = !self.gameState.isAttackLegal(charIndex: self.getCharacterIndex(), attackIndex: 4)
                self.attackBasic?.isHidden = false
                self.centerArrow?.isHidden = true
            }
        }
    }
    
    func hideBack(value: Bool){
        self.pressBack?.isHidden = value
    }
    
    func hideConfirm(value: Bool){
        self.pressConfirm?.isHidden = value
    }
    
    func hideGameButtons(value: Bool){
        DispatchQueue.main.async {
            self.move?.isHidden = value
            self.players?.isHidden = value
            self.attacks?.isHidden = value
            self.menu?.isHidden = value
            self.pHealthBar?.isHidden = value
            self.pEnergyBar?.isHidden = value
            self.eHealthBar?.isHidden = value
            self.eEnergyBar?.isHidden = value
            self.currentImage?.isHidden = value
        }
    }
    
    func defaultHide(){
        hideMovementButtons(value: true)
        hideAttackButtons(value: true)
        hideBack(value: true)
        hideConfirm(value: true)
        gameOverView.isHidden = true
        self.sendMapButton.isHidden = true
        hideGameButtons(value: true)
        self.confirmOutlineButton.isHidden = true
        devMode.isHidden = true
        self.onScreenDebugText.isHidden = !SHOW_ON_SCREEN_DEBUG_TEXT
    }
    
    func setMoveIndex(index: Int){
        updateSessionInfoLabel(for: sceneView.session.currentFrame!, state: "blank")
        if (curMovePart == 1){
            moveIndex1 = index
            updateCurMovePart(value: 2)
        }
        else {
            moveIndex2 = index
            updateCurMovePart(value: 3)
        }
    }
    
    func updateCurMovePart(value: Int){
        curMovePart = value
        if (curMovePart == 0){
            hideMovementButtons(value: true)
            hideAttackButtons(value: true)
            hideBack(value: true)
            hideConfirm(value: true)
        }
        else if (curMovePart == 1){
            onScreenDebugText.text = gameState.debug()
            updateSessionInfoLabel(for: sceneView.session.currentFrame!, state: "setDirection")
            hideMovementButtons(value: false)
            hideAttackButtons(value: true)
            hideBack(value: false)
            hideConfirm(value: true)
        }
        else if (curMovePart == 2){
            updateSessionInfoLabel(for: sceneView.session.currentFrame!, state: "setAttack")
            hideMovementButtons(value: false)
            hideAttackButtons(value: false)
            hideBack(value: false)
            hideConfirm(value: true)
        }
        else if (curMovePart == 3){
            updateSessionInfoLabel(for: sceneView.session.currentFrame!, state: "confirmMove")
            hideMovementButtons(value: true)
            hideAttackButtons(value: true)
            hideBack(value: false)
            move?.isHidden = true
            hideConfirm(value: false)
        }
        else {
            executeMove()
            updateCurMovePart(value: 0)
        }
    }
    
    func getMoveLabel() -> String{
        var label = "Confirm move of "
        if (moveIndex1 != CENTER_MOVE){
            label += (MOVE_DESCRIPTIONS[moveIndex1] + ", ")
        }
        label += MOVE_DESCRIPTIONS[moveIndex2]
        label += "?"
        return label
    }
    
    func getCharacterIndex() -> Int {
        if multipeerSession.host == multipeerSession.myPeerID
        {
            return 0
        }
        else{
            return 1
        }
    }
    
    
    func getAttackTiles(gameMove: GameMove) -> [SCNNode]{
        var list:[SCNNode] = []
        let attack = gameState.characters[getCharacterIndex()].attacks[gameMove.attackIndex]
        let attackRange = attack.range
        let playerX = gameState.characters[getCharacterIndex()].x
        let playerY = gameState.characters[getCharacterIndex()].y
        let length = gameState.board.length
        let width = gameState.board.width
        for row in 0..<length {
            for col in 0..<width {
                if (isTileHitByAttack(playerX: playerX, playerY: playerY, tileX: row, tileY: col, attackRange: attackRange)){
                    list.append(boardTiles[row][col])
                }
            }
        }
        return list
    }
    
    func executeMove(){
        let move = GameMove(moveIndex1: moveIndex1, moveIndex2: moveIndex2, charIndex: getCharacterIndex())

        updateGSHeightArray()
        
        gameState.handleMove(charIndex: self.getCharacterIndex(), move: move)
        onScreenDebugText.text = "Character index " + String(self.getCharacterIndex()) + "\nMove indices " + String(moveIndex1) + " " + String(moveIndex2)
        //not sending correct info right now - fix this. Server can only handle GameSimpleState
        let attack = gameState.package()
        
        do {let data = try NSKeyedArchiver.archivedData(withRootObject: attack, requiringSecureCoding: false)
            if((hero.currentTile.x + move.dx <= 6)
                && (hero.currentTile.z + move.dy <= 6)
                && (hero.currentTile.x + move.dx >= 0)
                && (hero.currentTile.z + move.dy >= 0))
            {
                animateMove(newTile: boardTiles[hero.currentTile.x + move.dx][hero.currentTile.z + move.dy], parent: hero.node)
            }
            if move.isAttack
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.75, execute: {
                    self.playAnimation(key: "hero-attack", parent: self.hero.node)
                    
                })
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                    self.generateParticles(_for: "hero", tiles: self.getAttackTiles(gameMove: move), damage: self.gameState.characters[self.getCharacterIndex()].attacks[move.attackIndex].baselineDamage);
               
                })
            }
            self.multipeerSession.sendToAllPeers(data)
            attackSent(sceneView.session)
            
        }
        catch{
            print("Failed to encode data")
        }
    }
    
    func setupStatusBars(){
        pHP = MetricBar(maxVal: Float(MAX_HEALTH), curVal: 0)
        pEP = MetricBar(maxVal: Float(MAX_ENERGY), curVal: Float(MAX_ENERGY))
        eHP = MetricBar(maxVal: Float(MAX_HEALTH), curVal: Float(MAX_HEALTH))
        eEP = MetricBar(maxVal: Float(MAX_ENERGY), curVal: Float(MAX_ENERGY))
        
        self.pHealthBar.progress = 1.0
        self.pEnergyBar.progress = 1.0
        self.eHealthBar.progress = 1.0
        self.eEnergyBar.progress = 1.0
    
        
        self.pHealthBar.progressTintColor =  UIColor(red:0.16, green:0.71, blue:0.39, alpha:1.0)
        self.eHealthBar.progressTintColor =  UIColor(red:0.16, green:0.71, blue:0.39, alpha:1.0)
        self.pEnergyBar.progressTintColor =  UIColor(red:0.26, green:0.20, blue:1.00, alpha:1.0)
        self.eEnergyBar.progressTintColor =  UIColor(red:0.26, green:0.20, blue:1.00, alpha:1.0)
        self.playerTurn = true
    }
    
    func changeTurns(){
        if(self.playerTurn){
            self.currentImage.image = bog
            self.playerTurn = false
            
        }else  {
            self.currentImage.image = sminem
            self.playerTurn = true
            
        }
    }
    
    
    //var count = 1
    func updateHealthVisual(){
        
        //count += 1
        var enemy: Int
        var player: Int
        if multipeerSession.myID == multipeerSession.host {
            enemy = 1
            player = 0
        }
        else{
            enemy = 0
            player = 1
        }
        
        /*
        self.eHP.curVal = Float(gameState.characters[enemy].health)
        self.pHP.curVal = Float(gameState.characters[player].health)
        
        self.pEP.curVal = Float(gameState.characters[enemy].health)
        self.eHP.curVal = Float(gameState.characters[enemy].energy)
         */
        
        self.pHP.curVal = Float(gameState.characters[player].health)
        self.pEP.curVal = Float(gameState.characters[player].energy)
        
        self.eHP.curVal = Float(gameState.characters[enemy].health)
        self.eEP.curVal = Float(gameState.characters[enemy].energy)
        
        DispatchQueue.main.async {
            self.changeTurns()
            self.pHealthBar.setProgress((self.pHP.curVal/self.pHP.maxVal), animated: true)
            self.pEnergyBar.setProgress((self.pEP.curVal/self.pEP.maxVal), animated: true)
            
            self.eHealthBar.setProgress((self.eHP.curVal/self.eHP.maxVal), animated: true)
            self.eEnergyBar.setProgress((self.eEP.curVal/self.eEP.maxVal), animated: true)
        }
        
    }
    
    func highlightTiles(){
        //let characterIndex = getCharacterIndex()
        let gameMove = GameMove(moveIndex1: moveIndex1, moveIndex2: moveIndex2, charIndex: getCharacterIndex())
        if (gameMove.isAttack){
            //let attack = gameState.characters[characterIndex].attacks[gameMove.attackIndex]
            highlightTilesFromAttack(characterIndex: getCharacterIndex(), move: gameMove)
        }
    }
    
    func highlightTilesFromAttack(characterIndex: Int, move: GameMove){
        let activeMat = SCNMaterial()
        activeMat.diffuse.contents = UIImage(named: "art.scnassets/activeTileMat.png")
        
        let moveMat = SCNMaterial()
        moveMat.diffuse.contents = UIImage(named: "art.scnassets/tileMat.png")
        
        let attack = gameState.characters[getCharacterIndex()].attacks[move.attackIndex]
        let attackRange = attack.range
        let playerX = gameState.characters[characterIndex].x + move.dx
        let playerY = gameState.characters[characterIndex].y + move.dy
        let length = gameState.board.length
        let width = gameState.board.width
        for row in 0..<length {
            for col in 0..<width {
                if (isTileHitByAttack(playerX: playerX, playerY: playerY, tileX: row, tileY: col, attackRange: attackRange)){
                    /*
                    //highlight tile
                    let gaussianBlurFilter = CIFilter(name: "CIGaussianBlur")
                    gaussianBlurFilter?.name = "blur"
                    let pixellateFilter = CIFilter(name:"CIPixellate")
                    pixellateFilter?.name = "pixellate"
                    let bloomFilter = CIFilter(name:"CIBloom")!
                    bloomFilter.name = "glow"
                    //bloomFilter.setValue(intensity, forKey: kCIInputIntensityKey)
                    boardTiles[row][col].filters = [ pixellateFilter, gaussianBlurFilter, bloomFilter ] as! [CIFilter]
                     */
                    if row == playerX && col == playerY
                    {
                        boardTiles[row][col].geometry?.materials = [moveMat]
                    }
                    else
                    {
                        boardTiles[row][col].geometry?.materials = [activeMat]
                    }
                }
            }
        }
        //generateParticles(_for: "highlight", tiles: tiles, damage: 15)
    }
    
    func unhighlightTiles() {
        for i in 0...6
        {
            for j in 0...6
            {
                let tileMat = SCNMaterial()
                tileMat.diffuse.contents = UIImage(named: "art.scnassets/tileMat.png")
                boardTiles[i][j].geometry?.materials = [tileMat]
            }
        }
    }
    
    func isTileHitByAttack(playerX: Int, playerY: Int, tileX: Int, tileY: Int, attackRange: Int) -> Bool{
        let dx = abs(tileX - playerX)
        let dy = abs(tileY - playerY)
        let dist = dx + dy
        return (dist <= attackRange)
    }
    
    //End BattleActions code
    
    //--------Sending / Recieving Map -------
    // MARK: - ARSCNViewDelegate
    /// - Tag: GetWorldMap
    @IBAction func shareSession(_ button: UIButton) {
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { print("Error: \(error!.localizedDescription)"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: false)
                else { fatalError("can't encode map") }
            self.multipeerSession.sendToAllPeers(data)
            self.hideGameButtons(value: false)
            self.sendMapButton.isHidden = true
            self.updateSessionInfoLabel(for: self.sceneView.session.currentFrame!, state: "gameStart")
            
        }
        let attack = gameState.package()

        do {let data = try NSKeyedArchiver.archivedData(withRootObject: attack, requiringSecureCoding: false)
             //self.multipeerSession.sendToAllPeers(data)
        }catch{
            
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    }
    
    // MARK: - AR session management
    private func loadTileModel() -> SCNNode {
        // Tom - add board rendering here
        let sceneURL = Bundle.main.url(forResource: "tileMat", withExtension: "png", subdirectory: "art.scnassets")!
        let referenceNode = SCNReferenceNode(url: sceneURL)!
        referenceNode.load()
        
        return referenceNode
    }
    
    //-------Sending and Recieving Actions -------
    
    func attackSent(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        updateSessionInfoLabel(for: session.currentFrame!, state: "sentAttack")
        //check for GameOver
        if(gameState.characters[0].health <= 0 || gameState.characters[1].health <= 0){
            gameOverView.isHidden = false
        }
        
    }
    func attackRecieved(prevHealth: Int, _ session: ARSession){
        updateSessionInfoLabel(for: session.currentFrame!, state: "recievedAttack")
        //check for gameOver
            hideGameButtons(value: false)
            var tile = SCNNode()
            var isAttack = false
            if multipeerSession.host == multipeerSession.myPeerID
            {
                tile = boardTiles[gameState.characters[1].x][gameState.characters[1].y]
                if gameState.characters[0].health != prevHealth
                {
                    isAttack = true
                }
            }
            else
            {
                tile = boardTiles[gameState.characters[0].x][gameState.characters[0].y]
                if gameState.characters[1].health != prevHealth
                {
                    isAttack = true
                }
            }
            
            animateMove(newTile: tile, parent: goblin.node)
            
            if isAttack
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.75, execute: {self.playAnimation(key: "goblin-swipe", parent: self.goblin.node)})
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.75, execute: {
                    self.generateParticles(_for: "goblin", tiles: [self.boardTiles[self.hero.currentTile.x][self.hero.currentTile.z]], damage: (prevHealth - self.gameState.characters[self.getCharacterIndex()].health));
                    
                })
            }
            updateHealthVisual()
            if(gameState.characters[0].health <= 0 || gameState.characters[1].health <= 0){
                gameOverView.isHidden = false
            }
        
    }
    private func updateSessionInfoLabel(for frame: ARFrame, state: String) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch state {
        case "boardSet":
            message = "Click Send World Map to share game with your peers"
        case "sentAttack":
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Attack Sent! Opponents turn"
            move?.isEnabled = true
        case "gameStart":
            if multipeerSession.myID != multipeerSession.sessionHost {
                message = "Game has started! Opponents Turn."
            } else{
                gameNotStarted = false
                message = "Game has started! Select your move."
            }
        case "recievedAttack":
            message = "Recieved Attack! Your Turn"
           // DispatchQueue.main.async {
             //   UIApplication.shared.stopIgnoringInteractionEvents()
            //}
        case "setDirection":
            message = "Select which direction you would like to move"
        case "setAttack":
            message = "Select which attack you would like to do"
        case "confirmMove":
            message = getMoveLabel()
            highlightTiles()
            
        case "attackInfo":
            message = "Work In Progress - Attack Info"
        case "pleaseWait":
            message = "Please wait! The game will start soon"
        case "characterInfo":
            message = "Work in progress - Character info"
        case "peerSettingBoard":
            message = "Other player is setting up the board! Please wait"
        case "waitingForPeer":
            message = "Waiting for player 2 to join game"
        case "blank":
            message = ""
        case "connected":
            setupStatusBars()
            let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            let host = multipeerSession.sessionHost
            if multipeerSession.myID == host {
                message = "Connected with \(peerNames). Click the screen to set a game board."
            }
            else{
                message = "Connected with \(peerNames). Please wait while your peer sets up the game"
                
            }
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }
        
        DispatchQueue.main.async {
            self.sessionInfoLabel.text = message
            self.sessionInfoView.isHidden = message.isEmpty
        }
        
    }
    @IBAction func sendAction(_ button: UIButton) {
        sendAttack()
  
    }
    func sendAttack(){
        let sendGameState = gameState.package()
        if(gameState.characters[0].health <= 0 || gameState.characters[0].health <= 0){
            gameOverView.isHidden = false
        }
        //Need to set turn label here for gameState
        if(multipeerSession.host == multipeerSession.myID){
            sendGameState.turn = 1
        }else{
            sendGameState.turn = 0
        }
        NSKeyedArchiver.setClassName("GameSimpleState", for:GameSimpleState.self)
        do {let data = try NSKeyedArchiver.archivedData(withRootObject: sendGameState, requiringSecureCoding: false)
            self.multipeerSession.sendToAllPeers(data)
            attackSent(sceneView.session)
        }
        catch{
            print("Failed to encode data")
        }
    }
    // End sending actions code
}

extension ViewController: MultipeerDelegate{
    func multipeerSession(_ session: MultipeerSession, sessionState:MCSessionState){
 //              updateSessionInfoLabel(for: sceneView.session.currentFrame!, state: "connected" )
    }
    
}
