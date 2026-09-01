//
//  Music.swift
//  Crazy Pyramid
//
//  Created by Banghua Zhao on 1/15/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import AVFoundation
import SpriteKit

/// Player audio preferences, persisted across launches. Both default to on.
enum AudioSettings {
    private enum Keys {
        static let music = "SETTINGS_MUSIC_ENABLED"
        static let soundEffects = "SETTINGS_SOUND_EFFECTS_ENABLED"
    }

    static var isMusicEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Keys.music) as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.music)
            if newValue {
                resumeBackgroundMusic()
            } else {
                stopBackgroundMusic()
            }
        }
    }

    static var isSoundEffectsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Keys.soundEffects) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Keys.soundEffects) }
    }
}

var backgroundMusicPlayer: AVAudioPlayer?

/// The track the current scene asked for, remembered so music can be restored
/// when the player turns it back on or returns from the background.
private var currentTrack: (filename: String, repeatForever: Bool)?

/// Set while something in the app deliberately wants silence -- currently the
/// in-game pause panel. Returning from the background must not override it and
/// start music playing behind a paused round.
var backgroundMusicHeld = false

func playBackgroundMusic(filename: String, repeatForever: Bool) {
    currentTrack = (filename, repeatForever)
    guard AudioSettings.isMusicEnabled else {
        stopBackgroundMusic()
        return
    }

    guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
        print("Could not find file: \(filename)")
        return
    }

    do {
        let player = try AVAudioPlayer(contentsOf: url)
        player.numberOfLoops = repeatForever ? -1 : 0
        player.prepareToPlay()
        player.play()
        backgroundMusicPlayer = player
    } catch {
        print("Could not create audio player!")
    }
}

func pauseBackgroundMusic() {
    backgroundMusicPlayer?.pause()
}

func resumeBackgroundMusic() {
    guard AudioSettings.isMusicEnabled, !backgroundMusicHeld else { return }
    if let player = backgroundMusicPlayer {
        player.play()
    } else if let track = currentTrack {
        playBackgroundMusic(filename: track.filename, repeatForever: track.repeatForever)
    }
}

func stopBackgroundMusic() {
    backgroundMusicPlayer?.stop()
    backgroundMusicPlayer = nil
}

/// Stops the music and forgets the track, so a settings change can't revive
/// the previous scene's music after leaving it.
func endBackgroundMusic() {
    currentTrack = nil
    backgroundMusicHeld = false
    stopBackgroundMusic()
}

extension SKScene {
    /// Plays a one-shot effect unless the player has muted sound effects.
    func playSoundEffect(_ action: SKAction) {
        guard AudioSettings.isSoundEffectsEnabled else { return }
        run(action)
    }
}
