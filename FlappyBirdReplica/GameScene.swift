//
//  GameScene.swift
//  FlappyBirdReplica
//
//  Created by Emmanuel Montano on 7/8/24.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var bird = SKSpriteNode()
    var bg = SKSpriteNode()
    
    let birdCategory: UInt32 = 1 << 0
    let objectCategory: UInt32 = 1 << 1
    let gapCategory: UInt32 = 1 << 2
    
    var gameOver = false
    
    var score = 0
    var scoreLabel = SKLabelNode()
    
    var gameTimer: Timer?
    
    static var backgroundMusicPlayer: AVAudioPlayer?
    static var flapSoundPlayer: AVAudioPlayer?
    static var hitSoundPlayer: AVAudioPlayer?
    
    override func didMove(to view: SKView) {
        // Configure the audio session
        configureAudioSession()
        
        // Play background music
        GameScene.playBackgroundMusic()
        
        // Set up physics
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -7) // Increased gravity to make the bird fall faster
        
        // Set up background
        let bgTexture = SKTexture(imageNamed: "bg")
        let moveBg = SKAction.move(by: CGVector(dx: -bgTexture.size().width, dy: 0), duration: 7)
        let replaceBg = SKAction.move(by: CGVector(dx: bgTexture.size().width, dy: 0), duration: 0)
        let moveBgForever = SKAction.repeatForever(SKAction.sequence([moveBg, replaceBg]))
        
        var i: CGFloat = 0
        
        while i < 3 {
            bg = SKSpriteNode(texture: bgTexture)
            bg.position = CGPoint(x: bgTexture.size().width * i, y: self.frame.midY)
            bg.size.height = self.frame.height
            bg.zPosition = -1
            bg.run(moveBgForever)
            self.addChild(bg)
            i += 1
        }
        
        // Set up bird
        let birdTexture = SKTexture(imageNamed: "flappy1")
        let birdTexture2 = SKTexture(imageNamed: "flappy2")
        
        let animation = SKAction.animate(with: [birdTexture, birdTexture2], timePerFrame: 0.1)
        let makeBirdFlap = SKAction.repeatForever(animation)
        
        bird = SKSpriteNode(texture: birdTexture)
        bird.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        bird.run(makeBirdFlap)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: birdTexture.size().height / 2)
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.contactTestBitMask = objectCategory | gapCategory
        bird.physicsBody?.collisionBitMask = objectCategory
        
        self.addChild(bird)
        
        // Set up ground
        let ground = SKNode()
        ground.position = CGPoint(x: self.frame.midX, y: -self.frame.height / 2)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.width, height: 1))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = objectCategory
        ground.physicsBody?.contactTestBitMask = birdCategory
        ground.physicsBody?.collisionBitMask = birdCategory
        
        self.addChild(ground)
        
        // Set up score label
        scoreLabel.fontName = "Helvetica"
        scoreLabel.fontSize = 60
        scoreLabel.text = "0"
        scoreLabel.position = CGPoint(x: self.frame.midX, y: self.frame.height / 2 - 100)
        scoreLabel.zPosition = 100
        self.addChild(scoreLabel)
        
        // Start the game
        startGame()
    }
    
    func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func startGame() {
        score = 0
        scoreLabel.text = "0"
        bird.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.allowsRotation = false
        gameOver = false
        
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(self.createPipes), userInfo: nil, repeats: true)
    }
    
    func endGame() {
        gameOver = true
        bird.physicsBody?.isDynamic = false
        bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        bird.removeAllActions() // Stop bird flapping animation
        bird.texture = SKTexture(imageNamed: "birdhitpipe")
        gameTimer?.invalidate()
        playHitSound()
    }
    
    @objc func createPipes() {
        if gameOver == false {
            let pipeGap: CGFloat = bird.size.height * 3
            
            let movementAmount = arc4random() % UInt32(self.frame.size.height / 2)
            let pipeOffset = CGFloat(movementAmount) - self.frame.size.height / 4
            
            let movePipes = SKAction.move(by: CGVector(dx: -2 * self.frame.size.width, dy: 0), duration: TimeInterval(self.frame.size.width / 100))
            let removePipes = SKAction.removeFromParent()
            let moveAndRemovePipes = SKAction.sequence([movePipes, removePipes])
            
            // Set up pipe texture
            let pipe1Texture = SKTexture(imageNamed: "pipe1")
            let pipe1 = SKSpriteNode(texture: pipe1Texture)
            pipe1.position = CGPoint(x: self.frame.midX + self.frame.size.width, y: self.frame.midY + pipe1Texture.size().height / 2 + pipeGap / 2 + pipeOffset)
            pipe1.run(moveAndRemovePipes)
            
            pipe1.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: pipe1Texture.size().width - 20, height: pipe1Texture.size().height - 20)) // Further reduced size for collision detection
            pipe1.physicsBody?.isDynamic = false
            pipe1.physicsBody?.categoryBitMask = objectCategory
            pipe1.physicsBody?.contactTestBitMask = birdCategory
            pipe1.physicsBody?.collisionBitMask = birdCategory
            
            self.addChild(pipe1)
            
            let pipe2Texture = SKTexture(imageNamed: "pipe2")
            let pipe2 = SKSpriteNode(texture: pipe2Texture)
            pipe2.position = CGPoint(x: self.frame.midX + self.frame.size.width, y: self.frame.midY - pipe2Texture.size().height / 2 - pipeGap / 2 + pipeOffset)
            pipe2.run(moveAndRemovePipes)
            
            pipe2.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: pipe2Texture.size().width - 20, height: pipe2Texture.size().height - 20)) // Further reduced size for collision detection
            pipe2.physicsBody?.isDynamic = false
            pipe2.physicsBody?.categoryBitMask = objectCategory
            pipe2.physicsBody?.contactTestBitMask = birdCategory
            pipe2.physicsBody?.collisionBitMask = birdCategory
            
            self.addChild(pipe2)
            
            let gap = SKNode()
            gap.position = CGPoint(x: self.frame.midX + self.frame.size.width, y: self.frame.midY + pipeOffset)
            gap.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: pipe1.size.width, height: pipeGap))
            gap.run(moveAndRemovePipes)
            
            gap.physicsBody?.isDynamic = false
            gap.physicsBody?.categoryBitMask = gapCategory
            gap.physicsBody?.contactTestBitMask = birdCategory
            
            self.addChild(gap)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameOver == false {
            bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 300)) // Original jump height
            playFlapSound()
        } else {
            let transition = SKTransition.fade(withDuration: 1.0)
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = self.scaleMode
            self.view?.presentScene(gameScene, transition: transition)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if gameOver == false {
            if contact.bodyA.categoryBitMask == gapCategory || contact.bodyB.categoryBitMask == gapCategory {
                score += 1
                scoreLabel.text = String(score)
            } else {
                endGame()
            }
        }
    }
    
    static func playBackgroundMusic() {
        if backgroundMusicPlayer == nil {
            if let musicURL = Bundle.main.url(forResource: "background", withExtension: "mp3") {
                do {
                    backgroundMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
                    backgroundMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
                    backgroundMusicPlayer?.volume = 0.33 // Set volume to 33%
                    backgroundMusicPlayer?.play()
                    print("Background music started")
                } catch {
                    print("Error playing background music: \(error)")
                }
            } else {
                print("Background music file not found")
            }
        }
    }
    
    func playFlapSound() {
        if let soundURL = Bundle.main.url(forResource: "flap", withExtension: "mp3") {
            do {
                if GameScene.flapSoundPlayer != nil && GameScene.flapSoundPlayer!.isPlaying {
                    GameScene.flapSoundPlayer?.stop()
                }
                GameScene.flapSoundPlayer = try AVAudioPlayer(contentsOf: soundURL)
                GameScene.flapSoundPlayer?.volume = 0.99 // Set volume to 99%
                GameScene.flapSoundPlayer?.play()
                print("Flap sound played")
            } catch {
                print("Error playing flap sound: \(error)")
            }
        } else {
            print("Flap sound file not found")
        }
    }
    
    func playHitSound() {
        if let soundURL = Bundle.main.url(forResource: "hit", withExtension: "mp3") {
            do {
                if GameScene.hitSoundPlayer != nil && GameScene.hitSoundPlayer!.isPlaying {
                    GameScene.hitSoundPlayer?.stop()
                }
                GameScene.hitSoundPlayer = try AVAudioPlayer(contentsOf: soundURL)
                GameScene.hitSoundPlayer?.volume = 0.99 // Set volume to 99%
                GameScene.hitSoundPlayer?.play()
                print("Hit sound played")
            } catch {
                print("Error playing hit sound: \(error)")
            }
        } else {
            print("Hit sound file not found")
        }
    }
}
