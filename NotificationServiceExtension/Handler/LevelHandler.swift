//
//  LevelHandler.swift
//  NotificationServiceExtension
//
//  Created by uuneo 2024/8/8.
//

import Foundation
import UserNotifications
import Defaults

/// 通知中断级别
class LevelHandler: NotificationContentHandler {
	
	func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
		
		let levelNumber = bestAttemptContent.getLevel()
        LevelHandler.setCriticalSound(content: bestAttemptContent)
		bestAttemptContent.interruptionLevel = self.getInterruptionLevel(from: levelNumber)
		return bestAttemptContent
	}

    func getInterruptionLevel(from levelNumber: UInt) -> UNNotificationInterruptionLevel {
        // 根据数字值返回对应的中断级别
        if (0...2).contains(levelNumber), let level = UNNotificationInterruptionLevel(rawValue: levelNumber) {
          return level
        }
        
        if (3...10).contains(levelNumber){  return .critical }
        return .active
    }
    
    class func setCriticalSound(content bestAttemptContent: UNMutableNotificationContent, soundName: String? = nil) {
        let level = bestAttemptContent.getLevel()
        
        guard  level > 2 else { return }
        // 默认音量
        let audioVolume: Float = bestAttemptContent.getVolume(levelNumber: level)
        // 设置重要警告 sound
        
        let sound = soundName ?? bestAttemptContent.soundName ?? "\(Defaults[.sound]).caf"
        
        bestAttemptContent.sound = UNNotificationSound.criticalSoundNamed(UNNotificationSoundName(rawValue: sound), withAudioVolume: audioVolume)
        
    }
}


extension UNMutableNotificationContent {
    
    var isCritical: Bool { self.getLevel() > 2 }
 
	/// 声音名称
	var soundName: String? {
        if let sound:String = self.userInfo.raw(Params.sound), sound.count > 0{
            return sound
        }
        return nil
    }

    func getLevel() -> UInt {
        // 默认值
        let defaultLevel: UInt = 1

        // 获取 level 字符串
        guard let level:String = self.userInfo.raw(Params.level) else {
            return defaultLevel
        }

        // 如果是 0~10 的数字字符串
        if let levelNumber = UInt(level), (0...10).contains(levelNumber) {
            return levelNumber
        }

        // 映射字符串等级
        let levelMap: [String: UInt] = [ "passive": 0, "active": 1, "timesensitive": 2, "critical": 3 ]

        // 返回匹配值或默认值
        return levelMap[level.lowercased()] ?? defaultLevel
    }


	func getVolume(levelNumber: UInt) -> Float{

        if let volume:String = self.userInfo.raw(Params.volume), let volume = Float(volume) {
            return max(0.0, min(10.0, volume / 10.0))
		}
        
        return max(0.0, min(10.0, Float(levelNumber) / 10.0))

	}

}
