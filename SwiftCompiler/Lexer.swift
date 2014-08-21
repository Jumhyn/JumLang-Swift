//
//  Lexer.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 7/25/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

class Lexer {

    var line: UInt = 0
    var characterIndex: String.Index

    var buffer: String

    var wordDict = Dictionary<String, Token>()

    var currentChar: Character {
        if !(characterIndex < buffer.endIndex) {
            return "\0"
        }
        else {
            return buffer[characterIndex]
        }
    }

    var nextChar: Character {
        advance()
        return currentChar
    }

    init(string: String) {
        buffer = string
        characterIndex = buffer.startIndex
        wordDict = ["true" : .Boolean(true),
            "false" : .Boolean(false),
            "if" : .If,
            "else" : .Else,
            "while" : .While,
            "do" : .Do,
            "break" : .Break,
            "return" : .Return,
            "char" : .Type(.charType()),
            "int" : .Type(.intType()),
            "float" : .Type(.floatType()),
            "bool" : .Type(.boolType()),
            "void" : .Type(.voidType())]
    }

    convenience init(_ file: String) {
        if let content = String.stringWithContentsOfFile(file, encoding: NSUTF8StringEncoding, error: nil) {
            self.init(string: content)
        }
        else {
            self.init(string: "")
        }
    }

    func nextToken() -> Token {
        while characterIndex < buffer.endIndex && currentChar == "/" || currentChar.isSpace() {
            while currentChar.isSpace() {
                if currentChar == "\t" || currentChar == " " {
                    advance()
                }
                else if currentChar == "\n" {
                    line++
                    advance()
                }
            }
            if currentChar == "/" && characterIndex < buffer.endIndex {
                if peek() == "/" {
                    while currentChar != "\n" && currentChar {
                        advance()
                    }
                    line++
                    advance()
                }
                else if peek() == "*" {
                    advance(2)
                    while currentChar != "\0" {
                        if currentChar == "*"  && characterIndex < buffer.endIndex {
                            if peek() == "/" {
                                advance(2);
                                break
                            }
                        }
                    }
                }
            }
        }
        if currentChar.isDigit() {
            var val = 0
            while currentChar.isDigit() {
                val = val * 10 + currentChar.toInt()!
                advance()
            }
            if currentChar == "." {
                advance()
                var doubleVal = Double(val)
                var powerOfTen: Double = 1.0
                while currentChar.isDigit() {
                    doubleVal += Double(currentChar.toInt()!) / (10.0 ^ powerOfTen)
                }
                return .Decimal(doubleVal)
            }
            else {
                return .Integer(val)
            }
        }
        else if currentChar.isAlpha() {
            var word = ""
            while currentChar.isAlpha() || currentChar.isDigit() {
                word += currentChar
                advance()
            }
            if let tok = wordDict[word] {
                return tok
            }
            else {
                wordDict[word] = .Identifier(word)
                return .Identifier(word)
            }
        }
        else if currentChar == "\"" {
            advance()
            var str = ""
            while peek() != "\"" || currentChar == "\\" {
                str += currentChar
            }
            str += currentChar
            advance(2)
            return .StringLiteral(str)
        }
        else {
            let lookback = currentChar
            var tok = String(currentChar, nextChar)
            switch tok {
            case "<=", ">=", "==", "!=", "&&", "||":
                advance()
                return Token(tok)

            default:
                return Token(lookback)
            }
        }
        if currentChar == "<" {
            advance()
            if currentChar == "=" {
                advance()
                return .LEqual
            }
            else {
                return .Less
            }
        }
        else if currentChar == ">" {
            advance()
            if currentChar == "=" {
                advance()
                return .GEqual
            }
            else {
                return .Greater
            }
        }
        else if currentChar == "=" {
            advance()
            if currentChar == "=" {
                advance()
                return .Equal
            }
            else {
                return .Assign
            }
        }
        else if currentChar == "!" {
            advance()
            if currentChar == "=" {
                advance()
                return .NEqual
            }
            else {
                return .Not
            }
        }
        else if currentChar == "&" {
            advance()
            if currentChar == "&" {
                advance()
                return .And
            }
        }
        else if currentChar == "|" {
            advance()
            if currentChar == "|" {
                advance()
                return .Or
            }
        }
        var ret = Token(currentChar)
        advance()
        return ret
    }

    func peek() -> Character {
        return buffer[characterIndex.successor()]
    }

    func advance() {
        characterIndex = characterIndex.successor()
    }

    func advance(num: Int) {
        num.times {
            self.advance()
        }
    }
}