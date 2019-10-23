//
//  MetricBar.swift
//  surface_detection
//
//  Created by Tom King on 3/25/19.
//  Copyright © 2019 jacobmiddleton15. All rights reserved.
//

import Foundation

class MetricBar {
    var maxVal: Float
    var curVal: Float
    var empty: BooleanLiteralType
    var full: BooleanLiteralType
    var curInt: Int
    var scale: Float
    
    //ADD ERROR CHECKING HERE
    init(maxVal: Float, curVal: Float) {
        self.maxVal = maxVal
        
        if(curVal >= maxVal){
            self.curVal = maxVal
            self.full = true
            self.empty = false
        }else if(curVal <= 0){
            self.curVal = 0
            self.empty = true
            self.full = false
        }else {
            self.curVal = curVal
            self.empty = false
            self.full = false
        }
        
        self.curInt = Int(self.curVal)
        self.scale = curVal/maxVal
    }
    
    func dmg(value: Float) {
        if(empty){
            return
        }else if( (self.curVal - value) <= 0 ){
            self.curVal  = 0
            self.empty = true
        }else{
            self.curVal -= value
            self.full = false
        }
        self.curInt = Int(self.curVal)
        self.scale = curVal/maxVal
    }
    
    func heal(value: Float){
        if(full){
            return
        }else if( (self.curVal + value) >= self.maxVal ){
            self.curVal  = self.maxVal
            self.full = true
        }else{
            self.curVal += value
            self.empty = false
        }
        self.curInt = Int(self.curVal)
        self.scale = curVal/maxVal
    }
    
    
}
