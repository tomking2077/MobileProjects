//
//  GameManager.swift
//  surface_detection
//
//  Created by Rachel Kellam on 4/15/19.
//  Copyright © 2019 jacobmiddleton15. All rights reserved.
//

import Foundation
import ARKit

class GameManager{
    var gameBoardIsPlaced = false
    var tileLength = Float(0.05)
    var minHeight = Float(0.00)
    var anchorY = Float(0.0)
    var boardTiles: [[SCNNode]] = []
    var heightDataArray: [[HeightData]] = []
    
    init(){
        gameBoardIsPlaced = false
        tileLength = Float(0.05)
        minHeight = Float(0.00)
        anchorY = Float(0.0)
        boardTiles = []
        heightDataArray = []
    
    }

    
    func createGameBoard(anchorPos: SCNVector3, sceneView: ARSCNView) {
        
        var tilePos = anchorPos
        tilePos.x -= tileLength * Float(4)
        tilePos.z -= tileLength * Float(4)
        
        //Column first order
        for _ in 1...8 {
            tilePos.x += tileLength
            
            //Column array
            var tileColArray: [SCNNode] = []
            var heightColArray: [HeightData] = []
            
            for _ in 1...8 {
                tilePos.z += tileLength
                tileColArray.append(createTile(position: tilePos))
                
                var tileHeightData = HeightData(curVal: anchorY)
                heightColArray.append(tileHeightData)
            }
            tilePos.z -= tileLength * Float(8)
            
            boardTiles.append(tileColArray)
            heightDataArray.append(heightColArray)
        }
        
        placeTiles(tiles: boardTiles, sceneView: sceneView)
        
    }
    
    func createTile(position: SCNVector3)-> SCNNode {
        let tileNode = SCNNode()
        let tileMat = SCNMaterial()
        tileMat.diffuse.contents = UIImage(named: "art.scnassets/tileMat.png")
        
        if !gameBoardIsPlaced {
            // Define tile properties
            let tileShape = SCNPlane(width: CGFloat(tileLength), height: CGFloat(tileLength) )
            tileNode.geometry = tileShape
            
            tileShape.materials = [tileMat]
            
            // Set tile position
            tileNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)     // SCNPlanes are vertical by default, so rotate
            tileNode.position = position                                            // and return to hit test position.
        }
        else {
            var boxHeight = Float(0)
            tileNode.position = position
            if position.y > anchorY {
                boxHeight = position.y - anchorY                    // Difference between Y value of hit test and gameboard anchor.
                tileNode.position.y = position.y - (boxHeight / 2)  // Position is center of SCNNode object (center of box).
            }
            else if position.y < anchorY {
                boxHeight = anchorY - position.y                    // Difference between Y value of hit test and gameboard anchor.
                tileNode.position.y = position.y + (boxHeight / 2)  // Offset SCNNode Y value so that it remains connected to game board.
            }
            
            let tileShape = SCNBox(width: CGFloat(tileLength), height: CGFloat(boxHeight), length: CGFloat(tileLength), chamferRadius: 0.0)
            tileNode.geometry = tileShape
            
            tileShape.materials = [tileMat]
        }
        
        return tileNode
    }
    
    func placeTiles(tiles: [[SCNNode]], sceneView: ARSCNView){
        for i in 0...7 {
            for j in 0...7 {
                tiles[i][j].name = "\(i)\(j)"
                sceneView.scene.rootNode.addChildNode(tiles[i][j])
            }
        }
    }
    
}
