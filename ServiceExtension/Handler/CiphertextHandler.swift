//
//  CiphertextHandler.swift
//  pushback
//
//  Created by uuneo 2024/11/23.
//

import Foundation
import UserNotifications

class CiphertextHandler:NotificationContentHandler{
	func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {

        var userInfo = bestAttemptContent.userInfo

        guard let ciphertext:String = userInfo.raw(.cipherText)  else {
			return bestAttemptContent
		}


		// 解密推送信息
		do {
            let ciphertNumber:Int = userInfo.raw(.cipherNumber) ?? 0

            let ivData: String? = userInfo.raw(.iv)
            let map = try self.decrypt(ciphertext: ciphertext,
                                       iv: ivData,
                                       number: ciphertNumber)

			var alert = [String: Any]()
			var soundName: String? = nil
            
            if let category: String = map.raw(.category, nesting: false), category == Identifiers.markdown.rawValue{
                bestAttemptContent.categoryIdentifier = category
            }else{
                bestAttemptContent.categoryIdentifier = Identifiers.myNotificationCategory.rawValue
            }

            /// map 不能使用.raw 因为没有aps的层级嵌套
            if let id:String = map.raw(.id, nesting: false){
                bestAttemptContent.targetContentIdentifier = id
            }


            if let title: String = map.raw(.title, nesting: false) {
                bestAttemptContent.title = title
                alert[Params.title.name] = title
			}
            
            
            if let subtitle: String = map.raw(.subtitle, nesting: false){
				bestAttemptContent.subtitle = subtitle
				alert[Params.subtitle.name] = subtitle
			}
            if let body: String = map.raw(.body, nesting: false) {
				bestAttemptContent.body = body
				alert[Params.body.name] = body
			}
            
            if let group: String = map.raw(.group, nesting: false)   {
				bestAttemptContent.threadIdentifier = group
			}
            
            
            if var sound: String = map.raw(.sound, nesting: false) {
				if !sound.hasSuffix(Params.caf.name) {
					sound = "\(sound).\(Params.caf.name)"
				}
				soundName = sound
				bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: sound))
			}
			
			var aps: [String: Any] = [Params.alert.name: alert]
			if let soundName {
				aps[Params.sound.name] = soundName
			}
			
			userInfo[Params.aps.name] = aps
			
			for (key,value) in map{
				userInfo[key] = value
			}
            
			bestAttemptContent.userInfo = userInfo

            return bestAttemptContent

		} catch {
			bestAttemptContent.title = String(localized: "解密失败!")
			bestAttemptContent.body = ciphertext
			bestAttemptContent.userInfo = [Params.aps.name: [Params.alert.name: [Params.body.name: bestAttemptContent.body,Params.title.name: bestAttemptContent.title]]]
			throw NotificationContentHandlerError.error(content: bestAttemptContent)
		}
		

	}
	
    
	// MARK: 解密
    func decrypt(ciphertext: String, iv: String? = nil, number:Int = 0) throws -> [AnyHashable: Any] {
        var cryptoConfig = Defaults[.cryptoConfigs].config(number)
		
		if let iv = iv { cryptoConfig.iv = iv }

		guard let json = CryptoManager(cryptoConfig).decrypt(base64: ciphertext),
			  let data = json.data(using: .utf8),
			  let map = JSON(data).dictionaryObject else { throw "JSON parsing failed"  }

		return map.reduce(into: [AnyHashable: Any]()) { $0[$1.key.lowercased()] = $1.value }
	}
	
}
