//
//  UnsafeBufferPointer+NSDataInitializable.swift
//  Swifty-Telehash
//
//  Created by David Waite on 10/12/15.
//  Copyright © 2015 Alkaline Solutions. All rights reserved.
//

import Foundation

extension UnsafeBufferPointer {
    init(_ data:NSData) {
        let count = data.length / sizeof(Element)
        let coercedPointer = UnsafePointer<Element>(data.bytes)
        self.init(start: coercedPointer, count: count)
    }
}