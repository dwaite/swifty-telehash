//
//  Base32Tests.swift
//  Swifty-Telehash
//
//  Created by David Waite on 10/1/15.
//  Copyright © 2015 Alkaline Solutions. All rights reserved.
//

import XCTest
import Foundation
import SwiftyTelehash

@testable import SwiftyTelehash

class Base32Tests: XCTestCase {

    var tVector:[(String, String)] = [
        ("",       ""),
        ("f",      "my======"),
        ("fo",     "mzxq===="),
        ("foo",    "mzxw6==="),
        ("foob",   "mzxw6yq="),
        ("fooba",  "mzxw6ytb"),
        ("foobar", "mzxw6ytboi======")]
    
    var tVectorNoPadding:[(String, String)] = [
        ("",       ""),
        ("f",      "my"),
        ("fo",     "mzxq"),
        ("foo",    "mzxw6"),
        ("foob",   "mzxw6yq"),
        ("fooba",  "mzxw6ytb"),
        ("foobar", "mzxw6ytboi")]
    func testEncodingRFCVector() {
        for (input, expectedResult) in tVector {
            let result = NSData(bytes: input, length: input.characters.count).base32EncodedData(true)
            assert(result == expectedResult)
        }
    }

    func testEncodingRFCVectorNoPadding() {
        for (input, expectedResult) in tVectorNoPadding {
            let result = NSData(bytes: input, length: input.characters.count).base32EncodedData(false)
            assert(result == expectedResult)
        }
    }
    
    func testDecodingRFCVector() {
        // TODO care about right number of padding characters

        for (expectedResult, input) in tVector {
            let expectedResultData = NSData(bytes: expectedResult, length: expectedResult.utf8.count)
            do {
                let result = try NSData(base32EncodedData: input)
                assert(result == expectedResultData)
            }
            catch {
                XCTFail("failure in input: \(input), error:\(error)")
            }
        }
    }
    
    func testDecodingRFCVectorNoPadding() {
        // TODO care about right number of padding characters
        
        for (expectedResult, input) in tVectorNoPadding {
            let expectedResultData = NSData(bytes: expectedResult, length: expectedResult.utf8.count)
            do {
                let result = try NSData(base32EncodedData: input)
                assert(result == expectedResultData)
            }
            catch {
                XCTFail("failure in input: \(input), error:\(error)")
            }
        }
    }

    func testDecodingFailureWhitespace() {
        let input = "mzxw6 ytboi"
        do {
            let result = try NSData(base32EncodedData: input, allowWhitespace:false)
            XCTFail("should have gotten a whitespace error, got \(result)")
        }
        catch {
            assert(error as! Base32EncodingError == Base32EncodingError.UnexpectedWhitespace)
        }
    }
    
    func testDecodingFailureInvalidCharacters() {
        let input = "value: mzxw6ytboi"
        do {
            let result = try NSData(base32EncodedData: input, ignoreInvalid: false )
            XCTFail("should have gotten an invalid character error, got \(result)")
        }
        catch {
            assert(error as! Base32EncodingError == Base32EncodingError.InvalidCharacter)
        }
    }
    
    func testDecodingFailureInvalidCharacterEmojis() {
        let input = "💩mzxw6ytboi"
        do {
            let result = try NSData(base32EncodedData: input, ignoreInvalid: false )
            XCTFail("should have gotten an invalid character error, got \(result)")
        }
        catch {
            assert(error as! Base32EncodingError == Base32EncodingError.InvalidCharacter)
        }
    }
    func testDecodingFailureUnexpectedPadding() {
        let input = "mzxw6yq="
        do {
            let result = try NSData(base32EncodedData: input, allowPadding:false)
            XCTFail("should have gotten an unexpected padding error, got \(result)")
        }
        catch {
            assert(error as! Base32EncodingError == Base32EncodingError.UnexpectedPadding)
        }
    }
    
    func testDecodingFailureInterstitialPadding() {
        let input = "mzxw=6yq"
        do {
            let result = try NSData(base32EncodedData: input)
            XCTFail("should have gotten an interstitial padding error, got \(result)")
        }
        catch {
            assert(error as! Base32EncodingError == Base32EncodingError.DataAfterPadding)
        }
    }
    
    func testDecodingFailureTypo() {
        let input = "11111111"
        do {
            let result = try NSData(base32EncodedData: input, allowTypos: false)
            XCTFail("should have gotten a typo error, got \(result)")
        }
        catch {
            assert(error as! Base32EncodingError == Base32EncodingError.SuspectedTypo)
        }
    }

    func testDecodingTypoCorrection() {
        let input = "11111111"
        let expectedResult = "LLLLLLLL"
        
        do {
            let decodedInput = try NSData(base32EncodedData: input)
            let decodedResult = try NSData(base32EncodedData: expectedResult)
            assert (decodedInput == decodedResult)
        }
        catch {
            XCTFail("Failure parsing input: \(error)")
        }
    }

    func testDecodingInvalidLength() {
        let input = "L"
        do {
            let result = try NSData(base32EncodedData: input)
            XCTFail("should have gotten a length error, got \(result)")
        }
        catch {
            assert(error as! Base32EncodingError == Base32EncodingError.InvalidDataLength)
        }
    }

}
