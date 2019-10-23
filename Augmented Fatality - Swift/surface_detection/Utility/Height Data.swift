//
//  HeightData.swift
//  surface_detection
//
//  Created by Tom King on 3/22/19.
//  Copyright © 2019 jacobmiddleton15. All rights reserved.
//

import Foundation

class HeightData {
    var curVal: Float
    var curCount: Int
    var betaVal: Float
    var maxMet: BooleanLiteralType
    var maxAvg: Int
    
    init(curVal: Float) {
        self.curVal = curVal
        self.curCount = 1
        self.maxMet = false
        self.betaVal = 0.2
        self.maxAvg = 16
    }
    
    func addVal(newVal: Float){
        let oldVal = self.curVal
        var total: Float
        
        if(curCount < self.maxAvg){
            total = (oldVal * Float(self.curCount) + newVal ) / Float(self.curCount + 1)
        }
        else{
            total = (1 - self.betaVal) * oldVal + self.betaVal * newVal;
        }
        self.curVal = total
        self.curCount += 1
        //print("OldVal: \(oldVal) NewVal: \(newVal) Curval: \(total) Count: \(self.curCount)" )
    }
}
