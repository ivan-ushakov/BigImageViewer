//
//  Log.swift
//  BigImageViewer
//
//  Created by  Ivan Ushakov on 23.02.2020.
//  Copyright © 2020 Lunar Key. All rights reserved.
//

import Foundation

final class Log {

    static func debug(_ message: String) {
        #if DEBUG
        print("DEBUG: \(message)")
        #endif
    }

    static func error(_ message: String) {
        #if DEBUG
        print("ERROR: \(message)")
        #endif
    }

    private init() {
    }
}
