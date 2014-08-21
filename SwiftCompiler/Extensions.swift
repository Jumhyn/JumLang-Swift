//
//  Extensions.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 8/4/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

@infix func <(lhs: String.Index, rhs: String.Index) -> Bool {
    return distance(lhs, rhs) > 0
}

@infix func >(lhs: String.Index, rhs: String.Index) -> Bool {
    return distance(lhs, rhs) < 0
}

@infix func ^(lhs: Double, rhs: Double) -> Double {
    return pow(lhs, rhs)
}

operator infix !^{}

@infix func !^(lhs: Bool, rhs: Bool) -> Bool {
    return !(lhs ^ rhs)
}

extension UInt {
    func times(block : () -> ()) {
        for i in 0..<self {
            block()
        }
    }
}

extension String {
    init(_ characters: Character...) {
        self.init(characters[0])
        for character in characters[1..<characters.count] {
            self += character
        }
    }
}

extension Character : LogicValue {
    public func getLogicValue() -> Bool {
        return self != "\0"
    }
}

extension Character {
    init(_ value: Int) {
        var scalar = UnicodeScalar(value)
        self.init(scalar)
    }

    func isSpace() -> Bool {
        var set = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        return set.characterIsMember(String(self).utf16[0])
    }
    func isDigit() -> Bool {
        var set = NSCharacterSet.decimalDigitCharacterSet()
        return set.characterIsMember(String(self).utf16[0])
    }
    func isAlpha() -> Bool {
        var set = NSCharacterSet.letterCharacterSet()
        return set.characterIsMember(String(self).utf16[0])
    }

    func toInt() -> Int? {
        return String(self).toInt()
    }

}