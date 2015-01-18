//
//  Extensions.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 8/4/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

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
            self.append(character)
        }
    }
}

extension String {
    func endsBasicBlock() -> Bool {
        return self.hasPrefix("ret") || self.hasPrefix("br") || self.hasPrefix("switch") || self.hasPrefix("indirectbr") ||
            self.hasPrefix("invoke") ||
            self.hasPrefix("resume") ||
            self.hasPrefix("unreachable")
    }
}

extension String {
    mutating func extendLn(other: String) {
        self.extend(other)
        let newLine: Character = "\n"
        self.append(newLine)
    }
}

extension Character : BooleanType {
    public var boolValue: Bool {
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