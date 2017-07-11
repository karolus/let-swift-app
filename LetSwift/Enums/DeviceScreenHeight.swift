//
//  ScreenDiagonalSize.swift
//  LetSwift
//
//  Created by Kinga Wilczek, Marcin Chojnacki on 13.04.2017.
//  Copyright © 2017 Droids On Roids. All rights reserved.
//

import UIKit

enum DeviceScreenHeight: CGFloat {
    case inch3¨5 = 480.0
    case inch4¨0 = 568.0
    case inch4¨7 = 667.0
    case inch5¨5 = 736.0
    case unknown = 0.0
    
    static let deviceHeight: DeviceScreenHeight = DeviceScreenHeight(rawValue: UIScreen.main.bounds.maxY) ?? .unknown
}

func ><T: RawRepresentable>(a: T, b: T) -> Bool where T.RawValue: Comparable {
    return a.rawValue > b.rawValue
}
