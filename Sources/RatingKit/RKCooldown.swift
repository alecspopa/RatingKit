//
//  RKCooldown.swift
//  RatingKit
//
//  Created by Alecs Popa on 16.06.26.
//


import Foundation
import SwiftUI

enum RKCooldown {
    static let days: Int = 30
    static var seconds: TimeInterval { TimeInterval(days * 86_400) }
}
