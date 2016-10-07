//
//  Extensions.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 8/4/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

extension UInt {
    func times(_ block : () -> ()) {
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
    mutating func append(line: String) {
        self += line
        let newLine: Character = "\n"
        self.append(newLine)
    }
}

extension Character {
    init(_ value: Int) {
        let scalar = UnicodeScalar(value)
        self.init(scalar!)
    }

    func isSpace() -> Bool {
        let set = CharacterSet.whitespacesAndNewlines
        return String(self).rangeOfCharacter(from: set) != nil
    }
    func isDigit() -> Bool {
        let set = CharacterSet.decimalDigits
        return String(self).rangeOfCharacter(from: set) != nil
    }
    func isAlpha() -> Bool {
        let set = CharacterSet.letters
        return String(self).rangeOfCharacter(from: set) != nil
    }

    func toInt() -> Int? {
        return Int(String(self))
    }

}
