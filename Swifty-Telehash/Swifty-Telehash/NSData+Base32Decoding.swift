//
//  Base32-Decoding.swift
//  Swifty-Telehash
//
//  Created by David Waite on 10/12/15.
//  Copyright © 2015 Alkaline Solutions. All rights reserved.
//

import Foundation

public enum Base32EncodingError : ErrorType {
    case UnexpectedWhitespace
    case UnexpectedPadding
    case SuspectedTypo
    case InvalidCharacter
    case DataAfterPadding
    case InvalidDataLength
}

public extension NSData {
    public convenience init(base32EncodedData: String,
        ignoreInvalid: Bool = true,
        allowWhitespace : Bool = true,
        allowPadding : Bool=true,
        allowTypos : Bool = true
        ) throws {
            var paddingEncountered:Bool = false
            var accumulator = DataAppender(capacity: maximumRequiredCapacity(base32EncodedData: base32EncodedData))
            
            try base32EncodedData.utf8.forEach() {
                char in
                let lookup = Int(char)
                guard lookup < 128 else {
                    if ignoreInvalid {
                        return; // skip this character
                    }
                    throw Base32EncodingError.InvalidCharacter
                }
                
                switch (SwiftyTelehash.Base32LookupDictionary[lookup],
                    ignoreInvalid, allowWhitespace, allowPadding, allowTypos, paddingEncountered) {
                case (.Invalid, true, _, _, _, _):
                    break
                case (.Invalid, false, _, _, _, _):
                    throw Base32EncodingError.InvalidCharacter
                    
                case (.Whitespace, _, true, _, _, _):
                    break
                case (.Whitespace, _, false, _, _, _):
                    throw Base32EncodingError.UnexpectedWhitespace
                    
                case (.Padding, _, _, true, _, _):
                    paddingEncountered = true
                    break
                case (.Padding, _, _, false, _, _):
                    throw Base32EncodingError.UnexpectedPadding
                    
                case (.Typo(let val), _, _, _, true, false):
                    accumulator.appendValue(val)
                    break
                case (.Typo(_), _, _, _, false, _):
                    throw Base32EncodingError.SuspectedTypo
                case (.Typo(_), _, _, _, true, true):
                    throw Base32EncodingError.DataAfterPadding
                    
                case (.Valid(let val), _, _, _, _, false):
                    accumulator.appendValue(val)
                    break
                case (.Valid(_), _, _, _, _, true):
                    throw Base32EncodingError.DataAfterPadding
                    
                default:
                    throw Base32EncodingError.InvalidCharacter
                }
            }
            do {
                self.init(data: try accumulator.result())
            }
            catch {
                throw Base32EncodingError.InvalidDataLength
            }
    }
}

internal enum DataAppenderError :ErrorType {
    case InvalidLength
    case InvalidInternalState
}

internal struct DataAppender {
    var pieces = 0
    var chunk = 0
    
    let accumulator:NSMutableData
    
    init() {
        accumulator = NSMutableData()
    }
    init(capacity:Int) {
        accumulator = NSMutableData(capacity: capacity)!
    }
    mutating func appendValue(value:UInt8) {
        guard value < 32 else {
            NSException(name: NSRangeException, reason: "value out of bounds", userInfo: nil).raiseNoReturn()
        }
        
        chunk = chunk << 5 + Int(value)
        pieces++
        
        if (pieces == 8) {
            var networkChunk = chunk.bigEndian;
            let longData = NSData(bytes: &networkChunk, length: sizeof(Int))
            let chunkData = longData.subdataWithRange(NSRange(location:3, length:5))
            accumulator.appendData(chunkData)
            pieces = 0
            chunk = 0
        }
    }
    
    mutating func reset() {
        pieces = 0
        chunk = 0
        accumulator.length = 0
    }
    
    mutating func result() throws -> NSData {
        var extraBitsOnChunk = 0
        var bytesOnChunk = 0
        // | 1 | 1 | 1 | 1 | 1 | 2 | 2 | 2 |
        // | 2 | 2 | 3 | 3 | 3 | 3 | 3 | 4 |
        // | 4 | 4 | 4 | 4 | 5 | 5 | 5 | 5 |
        // | 5 | 6 | 6 | 6 | 6 | 6 | 7 | 7 |
        // | 7 | 7 | 7 | 8 | 8 | 8 | 8 | 8 |
        if pieces > 0 {
            switch pieces {
            case 1:
                throw DataAppenderError.InvalidLength
            case 2:
                extraBitsOnChunk = 2
                bytesOnChunk = 1
                break
            case 3:
                throw DataAppenderError.InvalidLength
            case 4:
                extraBitsOnChunk = 4
                bytesOnChunk = 2
            case 5:
                extraBitsOnChunk = 1
                bytesOnChunk = 3
            case 6:
                throw DataAppenderError.InvalidLength
            case 7:
                extraBitsOnChunk = 3
                bytesOnChunk = 4
            default:
                throw DataAppenderError.InvalidInternalState
            }
            
            chunk >>= extraBitsOnChunk
            var networkChunk = chunk.bigEndian
            let longData = NSData(bytes: &networkChunk, length: sizeof(Int))
            let chunkData = longData.subdataWithRange(NSRange(location:8-bytesOnChunk, length:bytesOnChunk))
            accumulator.appendData(chunkData)
            pieces = 0
            chunk = 0
        }
        
        return accumulator.copy() as! NSData
    }
}
private func maximumRequiredCapacity(base32EncodedData base32EncodedData:String) -> Int {
    return base32EncodedData.utf8.count * 5 / 8
}