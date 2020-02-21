//
//  Hash.swift
//  BigImageViewer
//
//  Created by  Ivan Ushakov on 22.02.2020.
//  Copyright © 2020 Lunar Key. All rights reserved.
//

import Foundation
import CommonCrypto

import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

func MD5(string: String) -> String? {
    guard let messageData = string.data(using: .utf8) else {
        return nil
    }

    let length = Int(CC_MD5_DIGEST_LENGTH)
    var digestData = Data(count: length)
    digestData.withUnsafeMutableBytes { digestBytes -> Void in
        guard let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress else {
            return
        }

        messageData.withUnsafeBytes { messageBytes -> Void in
            if let messageBytesBaseAddress = messageBytes.baseAddress {
                let messageLength = CC_LONG(messageData.count)
                CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
            }
        }
    }

    return digestData.map { String(format: "%02hhx", $0) }.joined()
}
