//
//  GameBoard.swift
//  surface_detection
//
//  Created by crechkr on 3/5/19.
//  Copyright © 2019 jacobmiddleton15. All rights reserved.
//

import Foundation

class GameBoard {
    var length = 7
    var width = 7
    var array = Array(repeating: Array(repeating: GameCell(), count: 7), count: 7)

    init(_length: Int, _width: Int){
        self.length = _length;
        self.width = _width;
        self.array = Array(repeating: Array(repeating: GameCell(), count: self.length), count: self.width)
        for row in 0..<length {
            for column in 0..<width {
                array[row][column] = GameCell()
            }
        }
    }

    func isValidIndex(x: Int, y: Int) -> Bool{
        if (x >= length || x < 0 || y >= width || y < 0){
            return false
        }
        return !(array[x][y].occupied)
    }
    
    func debug() -> String{
        var debugstr = ""
        for row in array {
            var rowstr = ""
            for cell in row {
                if (cell.occupied){
                    rowstr += "x"
                }
                else {
                    rowstr += "o"
                }
            }
            rowstr += "\n"
            debugstr = rowstr + debugstr
        }
        return debugstr
    }
}
