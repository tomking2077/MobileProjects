//
//  GameStateTests.swift
//  surface_detection
//
//  Created by crechkr on 3/5/19.
//  Copyright © 2019 jacobmiddleton15. All rights reserved.
//

import UIKit

class GameStateTests: UIViewController {

    @IBOutlet weak var DisplayLabel: UILabel!
    @IBOutlet weak var BackButton: UIButton!
    
    let gameState = GameState()
    
    override func viewDidLoad() {
        DisplayLabel?.text = String(gameState.board.array[0][0].height);
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
