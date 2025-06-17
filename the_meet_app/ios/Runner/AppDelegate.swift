import Flutter
import UIKit
import MediaPlayer
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  private var isListening = false
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    
    // Setup method channel for Bluetooth media buttons
    methodChannel = FlutterMethodChannel(name: "bluetooth_media_buttons", binaryMessenger: controller.binaryMessenger)
    
    methodChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "startListening":
        self?.startListening(result: result)
      case "stopListening":
        self?.stopListening(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func startListening(result: @escaping FlutterResult) {
    guard !isListening else {
      result(false)
      return
    }
    
    // Request audio session
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
      try audioSession.setActive(true)
    } catch {
      print("Failed to setup audio session: \(error)")
      result(false)
      return
    }
    
    // Begin receiving remote control events
    UIApplication.shared.beginReceivingRemoteControlEvents()
    
    // Become first responder to receive remote control events
    if let controller = window?.rootViewController {
      controller.becomeFirstResponder()
    }
    
    // Setup media player command center
    setupRemoteCommandCenter()
    
    isListening = true
    result(true)
  }
  
  private func stopListening(result: @escaping FlutterResult) {
    guard isListening else {
      result(false)
      return
    }
    
    // Stop receiving remote control events
    UIApplication.shared.endReceivingRemoteControlEvents()
    
    // Resign first responder
    if let controller = window?.rootViewController {
      controller.resignFirstResponder()
    }
    
    // Disable remote command center
    disableRemoteCommandCenter()
    
    // Deactivate audio session
    do {
      try AVAudioSession.sharedInstance().setActive(false)
    } catch {
      print("Failed to deactivate audio session: \(error)")
    }
    
    isListening = false
    result(true)
  }
    private func setupRemoteCommandCenter() {
    let commandCenter = MPRemoteCommandCenter.shared()
    
    // Play command
    commandCenter.playCommand.addTarget { [weak self] event in
      self?.sendButtonEvent(action: "play")
      return .success
    }
    
    // Pause command
    commandCenter.pauseCommand.addTarget { [weak self] event in
      self?.sendButtonEvent(action: "pause")
      return .success
    }
    
    // Toggle play/pause command
    commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
      self?.sendButtonEvent(action: "toggle_play_pause")
      return .success
    }
    
    // Next track command
    commandCenter.nextTrackCommand.addTarget { [weak self] event in
      self?.sendButtonEvent(action: "next_track")
      return .success
    }
    
    // Previous track command
    commandCenter.previousTrackCommand.addTarget { [weak self] event in
      self?.sendButtonEvent(action: "previous_track")
      return .success
    }
    
    // Skip forward command
    commandCenter.skipForwardCommand.addTarget { [weak self] event in
      self?.sendButtonEvent(action: "skip_forward")
      return .success
    }
      // Skip backward command
    commandCenter.skipBackwardCommand.addTarget { [weak self] event in
      self?.sendButtonEvent(action: "skip_backward")
      return .success
    }
    
    // Stop command
    commandCenter.stopCommand.addTarget { [weak self] event in
      self?.sendButtonEvent(action: "stop")
      return .success
    }
    
    // Headset hook simulation - some devices send this as toggle play/pause
    // This might catch some volume button presses from certain Bluetooth devices
    
    // iOS 9.1+ - Like/Dislike commands (some devices map volume to these)
    if #available(iOS 9.1, *) {
      commandCenter.likeCommand.addTarget { [weak self] event in
        self?.sendButtonEvent(action: "volume_up")
        return .success
      }
      
      commandCenter.dislikeCommand.addTarget { [weak self] event in
        self?.sendButtonEvent(action: "volume_down")
        return .success
      }
    }
    
    // iOS 10.0+ - Additional commands
    if #available(iOS 10.0, *) {
      commandCenter.changeRepeatModeCommand.addTarget { [weak self] event in
        self?.sendButtonEvent(action: "headset_hook")
        return .success
      }
    }
    
    // Volume-related command attempts (iOS 7.1+)
    if #available(iOS 7.1, *) {
      commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
        if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
          // Some Bluetooth devices send volume as playback position changes
          let position = positionEvent.positionTime
          // Detect rapid position changes that might indicate volume gestures
          self?.sendButtonEvent(action: "playback_position_change")
        }
        return .success
      }
      
      // Enable playback rate command - sometimes volume comes through here
      commandCenter.changePlaybackRateCommand.addTarget { [weak self] event in
        if let rateEvent = event as? MPChangePlaybackRateCommandEvent {
          // Some devices send volume as playback rate changes
          if rateEvent.playbackRate > 1.0 {
            self?.sendButtonEvent(action: "volume_up")
          } else if rateEvent.playbackRate < 1.0 {
            self?.sendButtonEvent(action: "volume_down")
          }
        }
        return .success
      }
    }
    
    // Enable the commands
    commandCenter.playCommand.isEnabled = true
    commandCenter.pauseCommand.isEnabled = true
    commandCenter.togglePlayPauseCommand.isEnabled = true
    commandCenter.nextTrackCommand.isEnabled = true
    commandCenter.previousTrackCommand.isEnabled = true
    commandCenter.skipForwardCommand.isEnabled = true
    commandCenter.skipBackwardCommand.isEnabled = true
    commandCenter.stopCommand.isEnabled = true
    
    if #available(iOS 9.1, *) {
      commandCenter.likeCommand.isEnabled = true
      commandCenter.dislikeCommand.isEnabled = true
    }
    
    if #available(iOS 10.0, *) {
      commandCenter.changeRepeatModeCommand.isEnabled = true
    }
    
    if #available(iOS 7.1, *) {
      commandCenter.changePlaybackPositionCommand.isEnabled = true
      commandCenter.changePlaybackRateCommand.isEnabled = true
    }
  }    private func disableRemoteCommandCenter() {
    let commandCenter = MPRemoteCommandCenter.shared()
    
    // Remove all targets and disable commands
    commandCenter.playCommand.removeTarget(nil)
    commandCenter.pauseCommand.removeTarget(nil)
    commandCenter.togglePlayPauseCommand.removeTarget(nil)
    commandCenter.nextTrackCommand.removeTarget(nil)
    commandCenter.previousTrackCommand.removeTarget(nil)
    commandCenter.skipForwardCommand.removeTarget(nil)
    commandCenter.skipBackwardCommand.removeTarget(nil)
    commandCenter.stopCommand.removeTarget(nil)
    
    if #available(iOS 9.1, *) {
      commandCenter.likeCommand.removeTarget(nil)
      commandCenter.dislikeCommand.removeTarget(nil)
      commandCenter.likeCommand.isEnabled = false
      commandCenter.dislikeCommand.isEnabled = false
    }
    
    if #available(iOS 10.0, *) {
      commandCenter.changeRepeatModeCommand.removeTarget(nil)
      commandCenter.changeRepeatModeCommand.isEnabled = false
    }
    
    if #available(iOS 7.1, *) {
      commandCenter.changePlaybackPositionCommand.removeTarget(nil)
      commandCenter.changePlaybackPositionCommand.isEnabled = false
      commandCenter.changePlaybackRateCommand.removeTarget(nil)
      commandCenter.changePlaybackRateCommand.isEnabled = false
    }
    
    commandCenter.playCommand.isEnabled = false
    commandCenter.pauseCommand.isEnabled = false
    commandCenter.togglePlayPauseCommand.isEnabled = false
    commandCenter.nextTrackCommand.isEnabled = false
    commandCenter.previousTrackCommand.isEnabled = false
    commandCenter.skipForwardCommand.isEnabled = false
    commandCenter.skipBackwardCommand.isEnabled = false
    commandCenter.stopCommand.isEnabled = false
  }
  
  private func sendButtonEvent(action: String) {
    let timestamp = Int(Date().timeIntervalSince1970 * 1000) // milliseconds
    let eventData: [String: Any] = [
      "action": action,
      "timestamp": timestamp
    ]
    
    DispatchQueue.main.async { [weak self] in
      self?.methodChannel?.invokeMethod("onButtonPressed", arguments: eventData)
    }
  }
    // Handle remote control events (alternative method for some devices)
  override func remoteControlReceived(with event: UIEvent?) {
    guard let event = event, event.type == .remoteControl else { return }
    
    switch event.subtype {
    case .remoteControlPlay:
      sendButtonEvent(action: "play")
    case .remoteControlPause:
      sendButtonEvent(action: "pause")
    case .remoteControlTogglePlayPause:
      sendButtonEvent(action: "toggle_play_pause")
    case .remoteControlNextTrack:
      sendButtonEvent(action: "next_track")
    case .remoteControlPreviousTrack:
      sendButtonEvent(action: "previous_track")
    case .remoteControlStop:
      sendButtonEvent(action: "stop")
    case .remoteControlBeginSeekingForward:
      sendButtonEvent(action: "skip_forward")
    case .remoteControlEndSeekingForward:
      sendButtonEvent(action: "skip_forward")
    case .remoteControlBeginSeekingBackward:
      sendButtonEvent(action: "skip_backward")
    case .remoteControlEndSeekingBackward:
      sendButtonEvent(action: "skip_backward")
    default:
      // Some volume buttons might come through as unknown remote control events
      // Log them for debugging
      print("Unknown remote control event subtype: \(event.subtype.rawValue)")
      sendButtonEvent(action: "unknown_remote_control")
      break
    }
  }
}
