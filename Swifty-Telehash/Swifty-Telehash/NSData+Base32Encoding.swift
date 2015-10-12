//
//  Base32.swift
//  Swifty-Telehash
//
//  Created by David Waite on 10/1/15.
//  Copyright © 2015 Alkaline Solutions. All rights reserved.
//

import Foundation

let Base32Alphabet = "abcdefghijklmnopqrstuvwxyz234567".characters.map {$0}
let Base32PadCharacter = "="

public extension NSData {
    func base32EncodedData(padding:Bool = true) -> String {
        guard self.length > 0 else {
            return ""
        }
        let result   = NSMutableString()
        var partial:UInt8  = 0
        var index = 0
        
        // | 1 | 1 | 1 | 1 | 1 | 2 | 2 | 2 |
        // | 2 | 2 | 3 | 3 | 3 | 3 | 3 | 4 |
        // | 4 | 4 | 4 | 4 | 5 | 5 | 5 | 5 |
        // | 5 | 6 | 6 | 6 | 6 | 6 | 7 | 7 |
        // | 7 | 7 | 7 | 8 | 8 | 8 | 8 | 8 |
        self.enumerateByteRangesUsingBlock {
            (pointer, range, _) in
            assert(range.location == 0)
            let buffer = UnsafeBufferPointer(start: UnsafePointer<UInt8>(pointer), count: range.length)
            buffer.forEach() {
                byte in
                switch index % 5 {
                case 0:
                    result.appendString( String(Base32Alphabet[Int(byte >> 3)]) )
                    partial = (byte & 0x07) << 2
                case 1:
                    result.appendString( String(Base32Alphabet[Int( (byte >> 6) & 0x03 | partial)]) )
                    result.appendString( String(Base32Alphabet[Int( (byte >> 1) & 0x1f)]) )
                    partial = (byte & 0x01) << 4
                case 2:
                    result.appendString( String(Base32Alphabet[Int( (byte >> 4) & 0x0f | partial)]) )
                    partial = (byte & 0x0f) << 1
                case 3:
                    result.appendString( String(Base32Alphabet[Int( (byte >> 7) & 0x01 | partial)]) )
                    result.appendString( String(Base32Alphabet[Int( (byte >> 2) & 0x1f)]) )
                    partial = (byte & 0x03) << 3
                case 4:
                    result.appendString( String(Base32Alphabet[Int( (byte >> 5) & 0x07 | partial)]) )
                    result.appendString( String(Base32Alphabet[Int( byte & 0x1f)]) )
                    partial = 0
                default:
                    assert(index % 5 < 5)
                }
                index++
            }
        }
        if index % 5 != 0 {
            result.appendString( String(Base32Alphabet[Int( partial)]) )
            index++
        }
        if padding && result.length % 8 != 0 {
            let padCount = 7 - (result.length - 1) % 8
            for _ in 0..<padCount {
                result.appendString(Base32PadCharacter)
            }
        }
        return result as String
    }
}