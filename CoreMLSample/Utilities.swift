//
//  Utilities.swift
//  CoreMLSample
//
//  Created by Dinesh Harjani on 17/06/2017.
//  Copyright © 2017 杨萧玉. All rights reserved.
//

import Foundation
import UIKit

extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width, y: self.y * size.height)
    }
}

extension CGRect {
    func scaled(to size: CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x * size.width,
            y: self.origin.y * size.height,
            width: self.size.width * size.width,
            height: self.size.height * size.height
        )
    }
}
