//
//  GameSimpleState.swift
//  surface_detection
//
//  Created by crechkr on 3/25/19.
//  Copyright © 2019 jacobmiddleton15. All rights reserved.
//

import Foundation

class GameSimpleState : NSObject, NSCoding {
    required convenience init(coder aDecoder: NSCoder) {
        let dimension = aDecoder.decodeInteger(forKey: "dimension") as Int
        let heightArray = aDecoder.decodeObject(forKey: "heightArray") as! [[Float]]
        let characterOwners = aDecoder.decodeObject(forKey: "characterOwners") as! [Int]
        let characterX = aDecoder.decodeObject(forKey: "characterX") as! [Int]
        let characterY = aDecoder.decodeObject(forKey: "characterY") as! [Int]
        let characterHealth = aDecoder.decodeObject(forKey: "characterHealth") as! [Int]
        let characterEnergy = aDecoder.decodeObject(forKey: "characterEnergy") as! [Int]
        let turn = aDecoder.decodeInteger(forKey: "turn") as Int
        
        self.init(_dimension: dimension, _heightArray: heightArray, _characterOwners: characterOwners, _characterX: characterX, _characterY: characterY,_characterHealth: characterHealth,_characterEnergy: characterEnergy,_turn: turn)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.dimension, forKey: "dimension")
        coder.encode(self.heightArray, forKey: "heightArray")
        coder.encode(self.characterOwners, forKey: "characterOwners")
        coder.encode(self.characterX, forKey: "characterX")
        coder.encode(self.characterY, forKey: "characterY")
        coder.encode(self.characterHealth, forKey: "characterHealth")
        coder.encode(self.characterEnergy, forKey: "characterEnergy")
        coder.encode(self.turn, forKey: "turn")
    }
    
    var dimension = 7
    var heightArray = Array(repeating: Array(repeating: Float(0), count: 7), count: 7)
    var characterOwners = [0, 1]
    var characterX = [0, 6]
    var characterY = [0, 6]
    var characterHealth = [100, 100]
    var characterEnergy = [20, 20]
    var turn = 0
    
    
    init(_dimension: Int, _heightArray: [[Float]], _characterOwners: [Int], _characterX: [Int], _characterY: [Int],_characterHealth: [Int],_characterEnergy: [Int],_turn: Int){
        dimension =  _dimension
        heightArray = _heightArray
        characterOwners = _characterOwners
        characterX = _characterX
        characterY = _characterY
        characterHealth = _characterHealth
        characterEnergy = _characterEnergy
        turn = _turn
    }
    
    override init (){
        
    }
}
