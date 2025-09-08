//
//  ImageHandler.swift
//  NotificationServiceExtension
//
//  Created by uuneo 2024/8/8.
//


import UniformTypeIdentifiers
import Defaults
import UIKit


class MediaHandler:NotificationContentHandler{
	func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
		let userInfo = bestAttemptContent.userInfo
		
		
        if let imageUrl:String =  userInfo.raw(.image){
            
            guard let localPath = await ImageManager.downloadImage(imageUrl,mode: .image, expiration: .days(Defaults[.imageSaveDays].days)) else { return bestAttemptContent }

            /// 自动保存图片到相册 前提 打开了自动存储，并且缓存内没有的图片
            /// 每个图片只保存一遍
            if let uiimage = UIImage(contentsOfFile: localPath), Defaults[.autoSaveToAlbum], let sha256 = uiimage.pngData()?.sha256(){
                if Defaults[.imageSaves].first(where: {$0 == sha256}) == nil{
                    Defaults[.imageSaves].append(sha256)
                    UIImageWriteToSavedPhotosAlbum(uiimage, self, nil, nil)
                }
            }

			
			let copyDestUrl = URL(fileURLWithPath: localPath).appendingPathExtension(".tmp")
			// 将图片缓存复制一份，推送使用完后会自动删除，但图片缓存需要留着以后在历史记录里查看
			try? FileManager.default.copyItem(
				at: URL(fileURLWithPath: localPath),
				to: copyDestUrl
			)
			
			
			// MARK: - 此处提示按照下面修改
			///  import MobileCoreServices
			///  import UniformTypeIdentifiers
			///  'kUTTypePNG' was deprecated in iOS 15.0: Use  UTType.png.identifier
			let attachment = try UNNotificationAttachment(
				identifier: Params.image.name,
				url: copyDestUrl,
				options: [UNNotificationAttachmentOptionsTypeHintKey:  UTType.png.identifier]
			   
			)
			
			bestAttemptContent.attachments = [attachment]

		}
		
	
		return bestAttemptContent
    }
}

