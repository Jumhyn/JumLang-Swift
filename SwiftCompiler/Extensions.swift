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
        for _ in 0..<self {
            block()
        }
    }
}

extension String {
    init(characters: Character...) {
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
        self += other
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
        let scalar = UnicodeScalar(value)
        self.init(scalar)
    }

    func isSpace() -> Bool {
        let set = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        return set.characterIsMember(String(self).utf16[String.UTF16Index(_offset: 0)])
    }
    func isDigit() -> Bool {
        let set = NSCharacterSet.decimalDigitCharacterSet()
        return set.characterIsMember(String(self).utf16[String.UTF16Index(_offset: 0)])
    }
    func isAlpha() -> Bool {
        let set = NSCharacterSet.letterCharacterSet()
        return set.characterIsMember(String(self).utf16[String.UTF16Index(_offset: 0)])
    }

    func toInt() -> Int? {
        return Int(String(self))
    }

}