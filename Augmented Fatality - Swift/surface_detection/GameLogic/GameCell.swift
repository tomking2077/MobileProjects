//
//  GameCell.swift
//  surface_detection
//
//  Created by crechkr on 3/5/19.
//  Copyright © 2019 jacobmiddleton15. All rights reserved.
//

import Foundation

class GameCell {
    var height = Float(0)
    var occupied = false
    init(_height: Float, _occupied: Bool){
        self.height = _height
        self.occupied = _occupied
    }
    init(){
        
    }
}
