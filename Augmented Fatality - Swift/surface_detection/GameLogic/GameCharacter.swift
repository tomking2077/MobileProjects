//
//  GameCharacter.swift
//  surface_detection
//
//  Created by crechkr on 3/5/19.
//  Copyright © 2019 jacobmiddleton15. All rights reserved.
//

import Foundation

class GameCharacter {
    //Characters have 5 attacks. The basic attack is stored in index 0
    let MAX_ENERGY = 20
    
    var x = 0
    var y = 0
    var z = 0
    var health = 100
    var energy = 20
    var attacks = Array(repeating: GameAttack(), count: 5)
    init(_x: Int, _y: Int, _z: Int){
        self.x = _x
        self.y = _y
        self.z = _z
        setPresetAttacks()
    }
    init(){
        setPresetAttacks()
    }
    
    func setPresetAttacks(){
        for index in 0...4 {
            attacks[index] = createAttackFromPresets(type: index)
        }
    }
    
    func debug() -> String {
        return ("HP: " + String(health) + ", EN: " + String(energy) + ", POS: (" + String(x) + "," + String(y) + ")")
    }
    
    func createAttackFromPresets(type: Int) -> GameAttack{
        if (type == 1){
            return GameAttack(_baselineDamage: 20, _heightFactor: -2, _energyCost: 11, _range: 2)
        }
        if (type == 2){
            return GameAttack(_baselineDamage: 25, _heightFactor: 2, _energyCost: 5, _range: 1)
        }
        if (type == 3){
            return GameAttack(_baselineDamage: 15, _heightFactor: 1, _energyCost: 2, _range: 1)
        }
        if (type == 4){
            return GameAttack(_baselineDamage: 10, _heightFactor: -1, _energyCost: 8, _range: 3)
        }
        //Default: basic attack
        return GameAttack(_baselineDamage: 5, _heightFactor: 0, _energyCost: -5, _range: 1)
    }
}
