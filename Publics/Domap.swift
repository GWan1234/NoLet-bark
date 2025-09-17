//
//  Domap.swift
//  pushme
//
//  Created by lynn on 2025/9/8.
//

import Foundation



public enum Domap{
    static let KEY = "ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEF"
    static let IV = "ABCDEFGHIJKLMNOP"

    public static func generateRandomString(_ length: Int = 16) -> String {
        // 创建可用字符集（大写、小写字母和数字）
        let charactersArray = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        
        return String(Array(1...length).compactMap { _ in charactersArray.randomElement() })
    }
    
    
    
    public static func obfuscator(m: String, k: String, iv: String) -> String? {
        
       return k + "," + m + "," + iv
        
    }
    
    public static func deobfuscator(result: String) -> (String, String, String)? {
        
        let components = result.components(separatedBy: ",")

        guard components.count == 3 else {  return nil }
        
        return ( components[1], components[0], components[2])
    }
    
   
}

