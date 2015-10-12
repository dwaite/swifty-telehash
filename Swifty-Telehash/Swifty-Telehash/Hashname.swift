//
//  Hashname.swift
//  Swifty-Telehash
//
//  Created by David Waite on 10/12/15.
//  Copyright © 2015 Alkaline Solutions. All rights reserved.
//

import Foundation

enum HashnameError : ErrorType {
    case InvalidLength(length:Int)
}
struct Hashname {
    let byteValue:[UInt8]
    let stringValue:String

    init(value: String) throws {
        let parsedData = try NSData(base32EncodedData: value, ignoreInvalid: true, allowWhitespace: false, allowPadding: false, allowTypos: true)
        
        guard parsedData.length == 32 else {
            throw HashnameError.InvalidLength(length: parsedData.length)
        }
        
        // go ahead and store the 'normalized' value internally
        stringValue = parsedData.base32EncodedData()
        byteValue = [UInt8](UnsafeBufferPointer(parsedData))
    }
}