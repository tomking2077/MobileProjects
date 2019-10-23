//
//  GameState.swift
//  surface_detection
//
//  Created by crechkr on 3/5/19.
//  Copyright © 2019 jacobmiddleton15. All rights reserved.
//

import Foundation

class GameState {
    var board = GameBoard(_length: 7, _width: 7)
    var characters = [GameCharacter(_x: 3, _y: 6, _z: 0), GameCharacter(_x: 3, _y: 0, _z: 0)]
    
    init(){
        for character in characters {
            board.array[character.x][character.y].occupied = true
            
        }
    }
    
    func handleMove(charIndex: Int, move: GameMove){
        if (charIndex < 0 || charIndex >= characters.count){
            return
        }
        let prevX = characters[charIndex].x
        let prevY = characters[charIndex].y
        var newX = prevX + move.dx
        var newY = prevY + move.dy
        if (board.isValidIndex(x: newX, y: newY)){
            if (board.array[newX][newY].occupied == true){
                newX = prevX
                newY = prevY
            }
            else {
                board.array[prevX][prevY].occupied = false
                board.array[newX][newY].occupied = true
                characters[charIndex].x = newX
                characters[charIndex].y = newY
            }
        }
        else {
            newX = prevX
            newY = prevY
        }
        let attack = characters[charIndex].attacks[move.attackIndex];
        for i in 0..<characters.count {
            if (i == charIndex){
                continue
            }
            let character = characters[i]
            if characterHitByAttack(x1: newX, y1: newY, attack: attack, character: character){
                let myHeight = board.array[newX][newY].height
                let enemyHeight = board.array[character.x][character.y].height
                character.health -= Int(attack.calcDamage(myHeight: myHeight, enemyHeight: enemyHeight))
            }
        }
        characters[charIndex].energy = min(20, characters[charIndex].energy - attack.energyCost)
    }
    
    func characterHitByAttack(x1: Int, y1: Int, attack: GameAttack, character: GameCharacter) -> Bool {
        return (calcDist(x1: x1, y1: y1, x2: character.x, y2: character.y) <= attack.range)
    }
    
    func calcDist(x1: Int, y1: Int, x2: Int, y2: Int) -> Int {
        let xdif = abs(x1-x2)
        let ydif = abs(y1-y2)
        return xdif + ydif
    }
    
    func package() -> GameSimpleState {
        var gameSimpleState = GameSimpleState()
        gameSimpleState.dimension = board.length
        gameSimpleState.heightArray = packHeightArray()
        gameSimpleState.characterOwners = packCharacterOwners()
        gameSimpleState.characterX = packCharacterX()
        gameSimpleState.characterY = packCharacterY()
        gameSimpleState.characterHealth = packCharacterHealth()
        gameSimpleState.characterEnergy = packCharacterEnergy()
        gameSimpleState.turn = 0
        return gameSimpleState
    }
    
    func unpackage(gameSimpleState: GameSimpleState){
        board.length = gameSimpleState.dimension
        board.width = gameSimpleState.dimension
        unpackHeightArray(heightArray: gameSimpleState.heightArray)
        unpackCharacterX(characterDimension: gameSimpleState.characterX)
        unpackCharacterY(characterDimension: gameSimpleState.characterY)
        unpackCharacterHealth(characterDimension: gameSimpleState.characterHealth)
        unpackCharacterEnergy(characterDimension: gameSimpleState.characterEnergy)
        updateGameBoardOccupied()
    }
    
    func packHeightArray() -> Array<Array<Float> > {
        var heightArray = Array(repeating: Array(repeating: Float(0), count: board.width), count: board.length)
        
        for row in 0..<board.length {
            for col in 0..<board.width {
                heightArray[row][col] = Float(board.array[row][col].height)
            }
        }
        return heightArray
    }
    
    func unpackHeightArray(heightArray: Array<Array<Float> >){
        for row in 0..<board.length {
            for col in 0..<board.width {
                board.array[row][col].height = heightArray[row][col]
            }
        }
    }
    
    func packCharacterOwners() -> Array<Int> {
        var characterDimension = Array(repeating: 0, count: characters.count)
        for i in 0..<characters.count  {
            characterDimension[i] = i%2
        }
        return characterDimension
    }
    
    func packCharacterX() -> Array<Int> {
        var characterDimension = Array(repeating: 0, count: characters.count)
        for i in 0..<characters.count  {
            characterDimension[i] = characters[i].x
        }
        return characterDimension
    }
    
    func unpackCharacterX(characterDimension: Array<Int>){
        for i in 0..<characterDimension.count {
            characters[i].x = characterDimension[i]
        }
    }
    
    func packCharacterY() -> Array<Int> {
        var characterDimension = Array(repeating: 0, count: characters.count)
        for i in 0..<characters.count  {
            characterDimension[i] = characters[i].y
        }
        return characterDimension
    }
    
    func unpackCharacterY(characterDimension: Array<Int>){
        for i in 0..<characterDimension.count {
            characters[i].y = characterDimension[i]
        }
    }
    
    func packCharacterHealth() -> Array<Int> {
        var characterDimension = Array(repeating: 0, count: characters.count)
        for i in 0..<characters.count  {
            characterDimension[i] = Int(characters[i].health)
        }
        return characterDimension
    }
    
    func unpackCharacterHealth(characterDimension: Array<Int>){
        for i in 0..<characterDimension.count {
            characters[i].health = characterDimension[i]
        }
    }
    
    func packCharacterEnergy() -> Array<Int> {
        var characterDimension = Array(repeating: 0, count: characters.count)
        for i in 0..<characters.count  {
            characterDimension[i] = characters[i].energy
        }
        return characterDimension
    }
    
    func unpackCharacterEnergy(characterDimension: Array<Int>){
        for i in 0..<characterDimension.count {
            characters[i].energy = characterDimension[i]
        }
    }
    
    func updateGameBoardOccupied(){
        for row in 0..<board.length {
            for column in 0..<board.width {
                board.array[row][column].occupied = false
            }
        }
        for character in characters {
            board.array[character.x][character.y].occupied = true
        }
    }
    
    func isAttackLegal(charIndex: Int, attackIndex: Int) -> Bool{
        let curEnergy = characters[charIndex].energy
        let moveCost = characters[charIndex].attacks[attackIndex].energyCost
        return (moveCost <= curEnergy)
    }
    
    func debug() -> String{
        var debugstr = ""
        for character in characters {
            debugstr += (character.debug() + "\n")
        }
        debugstr += board.debug()
        return debugstr
    }
}
