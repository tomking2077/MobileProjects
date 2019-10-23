//
//  GameMove.swift
//  surface_detection
//
//  Created by crechkr on 3/6/19.
//  Copyright © 2019 jacobmiddleton15. All rights reserved.
//

import Foundation

class GameMove {
    /*
     The idea is that a move is initialized through two integers, each in the range of [0, 8]
     Each of these two integers corresponds to a square the user tapped on in the grid below
     
     0 1 2
     3 4 5
     6 7 8
     
     For example, the top center button corresponds to the up arrow, which will increment the character's x position
    */
    
    let DX_CONVERT = [0,  0, 0, -1, 0, 1, 0, 0, 0]
    let DY_CONVERT = [0, -1, 0,  0, 0, 0, 0, 1, 0]
    let IS_ATTACK = [true, false, true, false, true, false, true, false, true]
    let ATTACK_CONVERT = [1, -1, 2, -1, 0, -1, 3, -1, 4]

    var dx = 0
    var dy = 0
    var isAttack = true
    var attackIndex = 0
    
    init(moveIndex1: Int, moveIndex2: Int, charIndex: Int){
        if (isAttack(moveIndex: moveIndex2)){
            dx = indexToDx(moveIndex: moveIndex1)
            dy = indexToDy(moveIndex: moveIndex1)
            isAttack = true
            attackIndex = indexToAttack(moveIndex: moveIndex2)
        }
        else {
            dx = indexToDx(moveIndex: moveIndex1) + indexToDx(moveIndex: moveIndex2)
            dy = indexToDy(moveIndex: moveIndex1) + indexToDy(moveIndex: moveIndex2)
            isAttack = false
        }
        if (charIndex == 1){
            dx *= -1
            dy *= -1
        }
    }
    
    func indexToDx(moveIndex: Int) -> Int{
        return DX_CONVERT[moveIndex]
    }
    func indexToDy(moveIndex: Int) -> Int {
        return DY_CONVERT[moveIndex]
    }
    func isAttack(moveIndex: Int) -> Bool {
        return (IS_ATTACK[moveIndex])
    }
    func indexToAttack(moveIndex: Int) -> Int {
        return (ATTACK_CONVERT[moveIndex])
    }
}
