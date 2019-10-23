//
//  BattleActions.swift
//  surface_detection
//
//  Created by crechkr on 2/22/19.
//  Copyright © 2019 jacobmiddleton15. All rights reserved.
//

import UIKit

class BattleActions: UIViewController{
    
    let MOVE_DESCRIPTIONS = ["Attack 1", "Up", "Attack 2", "Left", "Basic Attack", "Right", "Attack 3", "Down", "Attack 4"]
    let CENTER_MOVE = 4
    
    var MY_CHAR_INDEX = 0 //networking dependent factor
    var gameState = GameState()
    
    var moveIndex1 = -1
    var moveIndex2 = -1
    var curMovePart = 1
    
    @IBOutlet weak var moveLabel:UILabel!
    @IBOutlet weak var debugLabel:UILabel!
    @IBOutlet weak var pressConfirm:UIButton?
    @IBOutlet weak var pressBack:UIButton?
    
    @IBOutlet weak var upArrow:UIButton?
    @IBOutlet weak var leftArrow:UIButton?
    @IBOutlet weak var rightArrow:UIButton?
    @IBOutlet weak var downArrow:UIButton?
    @IBOutlet weak var centerArrow:UIButton?
    @IBOutlet weak var attackBasic:UIButton?
    @IBOutlet weak var attack1:UIButton?
    @IBOutlet weak var attack2:UIButton?
    @IBOutlet weak var attack3:UIButton?
    @IBOutlet weak var attack4:UIButton?
    
    @IBOutlet weak var pHealthBar:UIProgressView!
    @IBOutlet weak var pEnergyBar:UIProgressView!
    @IBOutlet weak var eHealthBar:UIProgressView!
    @IBOutlet weak var eEnergyBar:UIProgressView!
    @IBOutlet weak var currentImage:UIImageView!
    @IBOutlet weak var boxPlayer:UIImageView!
    @IBOutlet weak var boxEnemy:UIImageView!
    
    var pHP = MetricBar(maxVal: 100, curVal: 100)
    var pEP = MetricBar(maxVal: 100, curVal: 100)
    var eHP = MetricBar(maxVal: 100, curVal: 50)
    var eEP = MetricBar(maxVal: 100, curVal: 50)
    let bog = UIImage(named: "bog.jpg")
    let sminem = UIImage(named: "sminem.jpg")
    var playerTurn = Bool(true)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setMoveLabel(s: "default")
        defaultHide()
        setDebugLabel()
        setupStatusBars()
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(swipe:)))
        leftSwipe.direction = UISwipeGestureRecognizer.Direction.left
        self.view.addGestureRecognizer(leftSwipe)
    }
    
    @IBAction func pressConfirm(_ sender: Any) {
        setMoveLabel(s: "")
        updateCurMovePart(value: 4)
    }
    
    @IBAction func pressBack(_ sender: Any) {
        setMoveLabel(s: "")
        updateCurMovePart(value: curMovePart - 1)
    }
    
    @IBAction func pressMove(_ sender: Any) {
        setMoveLabel(s: "")
        updateCurMovePart(value: 1)
    }
    
    @IBAction func pressMenu(_ sender: Any) {
        setMoveLabel(s: "")
    }
    
    @IBAction func pressPlayerInfo(_ sender: Any) {
        setMoveLabel(s: "Work in progress")
    }
    
    @IBAction func pressAttackInfo(_ sender: Any) {
        setMoveLabel(s: "Work in progress")
    }
    
    @IBAction func pressAttack1(_ sender: Any) {
        setMoveIndex(index: 0)
    }
    
    @IBAction func pressUp(_ sender: Any) {
        setMoveIndex(index: 1)
    }
    
    @IBAction func pressAttack2(_ sender: Any) {
        setMoveIndex(index: 2)
    }
    
    @IBAction func pressLeft(_ sender: Any) {
        setMoveIndex(index: 3)
    }
    
    @IBAction func pressCenter(_ sender: Any) {
        setMoveIndex(index: 4)
    }
    
    @IBAction func pressRight(_ sender: Any) {
        setMoveIndex(index: 5)
    }
    
    @IBAction func pressAttack3(_ sender: Any) {
        setMoveIndex(index: 6)
    }
    
    @IBAction func pressDown(_ sender: Any) {
        setMoveIndex(index: 7)
    }
    
    @IBAction func pressAttack4(_ sender: Any) {
        setMoveIndex(index: 8)
    }
    
    func setMoveLabel(s: String){
        moveLabel?.text = s
    }
    
    func setDebugLabel(){
        debugLabel?.text = gameState.debug()
    }
    
    func hideMovementButtons(value: Bool){
        self.upArrow?.isHidden = value
        self.leftArrow?.isHidden = value
        self.rightArrow?.isHidden = value
        self.downArrow?.isHidden = value
        self.centerArrow?.isHidden = value
    }
    
    func hideAttackButtons(value: Bool){
        self.attack1?.isHidden = value
        self.attack2?.isHidden = value
        self.attack3?.isHidden = value
        self.attack4?.isHidden = value
        self.attackBasic?.isHidden = value
        if (!value){
            self.centerArrow?.isHidden = true
        }
    }
    
    func hideBack(value: Bool){
        self.pressBack?.isHidden = value
    }
    
    func hideConfirm(value: Bool){
        self.pressConfirm?.isHidden = value
    }
    
    func defaultHide(){
        hideMovementButtons(value: true)
        hideAttackButtons(value: true)
        hideBack(value: true)
        hideConfirm(value: true)
    }
    
    func setMoveIndex(index: Int){
        setMoveLabel(s: "")
        if (curMovePart == 1){
            moveIndex1 = index
            updateCurMovePart(value: 2)
        }
        else {
            moveIndex2 = index
            updateCurMovePart(value: 3)
        }
    }
    
    func updateCurMovePart(value: Int){
        curMovePart = value
        if (curMovePart == 0){
            setMoveLabel(s: "Your turn - select an action")
            hideMovementButtons(value: true)
            hideAttackButtons(value: true)
            hideBack(value: true)
            hideConfirm(value: true)
        }
        else if (curMovePart == 1){
            setMoveLabel(s: "Select a directional move")
            hideMovementButtons(value: false)
            hideAttackButtons(value: true)
            hideBack(value: false)
            hideConfirm(value: true)
        }
        else if (curMovePart == 2){
            setMoveLabel(s: "Select an attacking move")
            hideMovementButtons(value: false)
            hideAttackButtons(value: false)
            hideBack(value: false)
            hideConfirm(value: true)
        }
        else if (curMovePart == 3){
            setMoveLabel(s: getMoveLabel())
            hideMovementButtons(value: true)
            hideAttackButtons(value: true)
            hideBack(value: false)
            hideConfirm(value: false)
        }
        else {
            executeMove()
            updateCurMovePart(value: 0)
        }
    }
    
    func getMoveLabel() -> String{
        var label = "Confirm move of "
        if (moveIndex1 != CENTER_MOVE){
            label += (MOVE_DESCRIPTIONS[moveIndex1] + ", ")
        }
        label += MOVE_DESCRIPTIONS[moveIndex2]
        label += "?"
        return label
    }
    
    func executeMove(){
        let move = GameMove(moveIndex1: moveIndex1, moveIndex2: moveIndex2, charIndex: MY_CHAR_INDEX)
        gameState.handleMove(charIndex: MY_CHAR_INDEX, move: move)
        setDebugLabel()
    }
    
    func setupStatusBars(){
        pHP = MetricBar(maxVal: 100, curVal: 100)
        pEP = MetricBar(maxVal: 100, curVal: 100)
        eHP = MetricBar(maxVal: 100, curVal: 50)
        eEP = MetricBar(maxVal: 100, curVal: 50)
        
        self.pHealthBar.progressTintColor =  UIColor(red:0.16, green:0.71, blue:0.39, alpha:1.0)
        self.eHealthBar.progressTintColor =  UIColor(red:0.16, green:0.71, blue:0.39, alpha:1.0)
        self.pEnergyBar.progressTintColor =  UIColor(red:0.26, green:0.20, blue:1.00, alpha:1.0)
        self.eEnergyBar.progressTintColor =  UIColor(red:0.26, green:0.20, blue:1.00, alpha:1.0)
        self.boxEnemy.isHidden = true
        self.playerTurn = true
    }
    
    func changeTurns(){
        if(self.playerTurn){
            self.boxPlayer.isHidden = true
            self.boxEnemy.isHidden = false
            self.currentImage.image = bog
            self.playerTurn = false
            
        }else  {
            self.boxEnemy.isHidden = true
            self.boxPlayer.isHidden = false
            self.currentImage.image = sminem
            self.playerTurn = true
            
        }
    }
    
    
    //var count = 1
    func randDMG(){
        //count += 1
        let max = 40
        let pHealth = Int.random(in: 0 ... max)
        let pEnergy = Int.random(in: 0 ... max)
        let eHealth = Int.random(in: 0 ... max)
        let eEnergy = Int.random(in: 0 ... max)
        let dmgorhealth = Int.random(in: 0 ... 1)
        
        if(dmgorhealth == 1){
            self.eHP.heal(value: Float(eHealth))
            self.eEP.dmg(value: Float(eEnergy))
            
            self.pHP.dmg(value: Float(pHealth))
            self.pEP.heal(value: Float(pEnergy))
            
        }else{
            self.pHP.heal(value: Float(pHealth))
            self.pEP.dmg(value: Float(pEnergy))
            
            self.eHP.dmg(value: Float(eHealth))
            self.eEP.heal(value: Float(eEnergy))
        }
        
        /*
         if(count == 2){
         count = 0
         if(currentImage.image != nil && currentImage.image!.isEqual(bog) ) {
         currentImage.image = sminem
         }else{
         currentImage.image = bog
         }
         }*/
        
        self.pHealthBar.setProgress(pHP.scale, animated: true)
        self.eHealthBar.setProgress(eHP.scale, animated: true)
        self.pEnergyBar.setProgress(pEP.scale, animated: true)
        self.eEnergyBar.setProgress(eEP.scale, animated: true)
        
        
        //DEBUG
        //print("pHP: \(pHP.curVal) eHP: \(eHP.curVal) pEP: \(pEP.curVal) eEP: \(eEP.curVal)")
        
        changeTurns()
    }
    
    @objc func swipeAction(swipe: UISwipeGestureRecognizer){
        randDMG()
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
