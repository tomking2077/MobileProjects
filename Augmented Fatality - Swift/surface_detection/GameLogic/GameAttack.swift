//
//  GameAttack.swift
//  surface_detection
//
//  Created by crechkr on 3/5/19.
//  Copyright © 2019 jacobmiddleton15. All rights reserved.
//

import Foundation

class GameAttack : NSObject, NSCoding {
    required convenience init(coder aDecoder: NSCoder) {
        let baselineDamage = aDecoder.decodeInteger(forKey: "baselineDamage") as Int
        let heightFactor = aDecoder.decodeInteger(forKey: "heightFactor") as Int
        let energyCost = aDecoder.decodeInteger(forKey: "energyCost") as Int
        let range = aDecoder.decodeInteger(forKey: "range") as Int
        self.init(_baselineDamage: baselineDamage, _heightFactor: heightFactor, _energyCost: energyCost, _range: range)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.baselineDamage, forKey: "baselineDamage")
        coder.encode(self.heightFactor, forKey: "heightFactor")
        coder.encode(self.energyCost, forKey: "energyCost")
        coder.encode(self.range, forKey: "range")
    }
    
    
    var baselineDamage = 0
    var heightFactor = 0
    var energyCost = 0
    var range = 0
    
    init(_baselineDamage: Int, _heightFactor: Int, _energyCost: Int, _range: Int){
        baselineDamage =  _baselineDamage
        heightFactor = _heightFactor
        energyCost = _energyCost
        range = _range
    }
    
    override init (){
        baselineDamage = 1
        heightFactor = 0
        energyCost = 0
        range = 1
    }
    
    func calcDamage(myHeight: Float, enemyHeight:Float) -> Float {
        let heightDiff = enemyHeight - Float(myHeight)
        return Float(baselineDamage) + Float(heightFactor) * heightDiff
    }
}
