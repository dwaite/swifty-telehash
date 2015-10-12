//
//  NSException+RaiseNoReturn.swift
//  Swifty-Telehash
//
//  Created by David Waite on 10/12/15.
//  Copyright © 2015 Alkaline Solutions. All rights reserved.
//

import Foundation

internal extension NSException {
    @noreturn func raiseNoReturn() {
        self.raise()
        abort()
    }
}