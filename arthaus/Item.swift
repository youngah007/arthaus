//
//  Item.swift
//  arthaus
//
//  Created by Andrew Young on 4/8/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
