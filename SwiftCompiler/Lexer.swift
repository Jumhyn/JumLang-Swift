//
//  Lexer.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 7/25/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

class Lexer {

    var line: UInt = 1
    var characterIndex: String.Index

    //buffer that stores the full string of the file currently being lexed
    var buffer: String

    //dict that stores alphanumeric strings and their corresponding tokens
    var wordDict = Dictionary<String, Token>()

    //return the character at the current index, unless we're at the end of the buffer, then return the null character
    var currentChar: Character {
        if characterIndex == buffer.endIndex {
            return "\0"
        }
        else {
            return buffer[characterIndex]
        }
    }

    //designated initializer: set up the buffer, index, and populate the word dict with our reserved words
    init(_ string: String) {
        buffer = string
        characterIndex = buffer.startIndex
        wordDict = [
            "true" : .boolean(true),
            "false" : .boolean(false),
            "if" : .if,
            "else" : .else,
            "while" : .while,
            "do" : .do,
            "break" : .break,
            "return" : .return,
            "struct" : .struct,
            "char" : .typeName(.charType()),
            "int" : .typeName(.intType()),
            "float" : .typeName(.floatType()),
            "bool" : .typeName(.boolType()),
            "void" : .typeName(.voidType())
        ]
    }

    //load the file if it contains anything, otherwise initialize with an empty string
    convenience init(file: String) {
        do {
            let content = try String(contentsOfFile:file, encoding: String.Encoding.utf8)
            self.init(content)
        } catch _ {
            self.init("")
        }
    }

    //advance forward one character and return the current character
    func nextChar() -> Character {
        advance()
        return currentChar
    }

    func nextToken() -> Token {
        skipIgnoredChars()
        if currentChar.isDigit() {
            return getNumToken()
        }
        else if currentChar.isAlpha() {
            return getWordToken()
        }
        else if currentChar == "\"" {
            return getStringToken()
        }
        else { //... if the following token is not a number, word, or string literal, it must be some other symbol
            let lookback = currentChar
            switch String(characters: currentChar, nextChar()) {
            case let tok where ["<=", ">=", "==", "!=", "&&", "||"].contains(tok):
                //two character token
                advance()
                return Token(tok)

            default:
                //single character token
                return Token(lookback)
            }
        }
    }

    func hasToken() -> Bool {
        if currentChar != "\0" {
            return true
        }
        else {
            return false
        }
    }

    fileprivate func skipIgnoredChars() {
        while currentChar == "/" || currentChar.isSpace() { //as long as there are comments or whitespace, skip them
            if currentChar == "/" {
                switch nextChar() {
                case "/": //the next two characters are "//", so skip the rest of the line
                    while currentChar != "\n" && currentChar != "\0" {
                        advance()
                    }
                    line += 1
                    advance()
                case "*": //the next two characters are "/*" so skip until we find "*/"
                    while nextChar() != "\0" {
                        if currentChar == "*" {
                            if nextChar() == "/" {
                                break
                            }
                        }
                    }
                    advance(2)
                default:
                    recede()
                }
            }
            while currentChar.isSpace() { //skip any whitespace, while keeping track of newlines
                if currentChar == "\n" {
                    line += 1
                }
                advance()
            }
        }
    }

    fileprivate func getNumToken() -> Token {
        var val = 0
        while currentChar.isDigit() { //loop through digit by digit until we hit something that isnt a digit
            val = val * 10 + currentChar.toInt()!
            advance()
        }
        if currentChar == "." { //if it's a decimal point, we have a decimal number...
            advance()
            var doubleVal = Double(val)
            var powerOfTen: Double = 1.0
            while currentChar.isDigit() {
                doubleVal += Double(currentChar.toInt()!) / pow(10.0, powerOfTen)
                powerOfTen += 1
                advance()
            }
            return .decimal(doubleVal)
        }
        else {
            return .integer(val)
        }
    }

    fileprivate func getWordToken() -> Token {
        let startIndex = characterIndex
        while currentChar.isAlpha() || currentChar.isDigit() { //as long as we have an alphanumeric character, keep going
            advance()
        }
        let word = buffer[startIndex..<characterIndex] //create the word from the characters we've passed over
        if let tok = wordDict[word] { //if the work exists/has a token already, use the dict entry
            return tok
        }
        else { //...otherwise, it's a new identifier, so add it to the dictionary!
            wordDict[word] = .identifier(word)
            return .identifier(word)
        }
    }

    fileprivate func getStringToken() -> Token {
        advance() //skip over opening quote that brought us here
        let startIndex = characterIndex
        while nextChar() != "\"" { //until we encounter a closing quote, skip over characters
            if currentChar == "\\" && nextChar() == "\"" { //if the quote is escaped, then skip over!
                advance()
            }
        }
        let str = buffer[startIndex..<characterIndex] //create the string like we did the word
        advance()
        return .stringLiteral(str)
    }

    fileprivate func advance() {
        if !(characterIndex == buffer.endIndex) {
            characterIndex = buffer.index(after: characterIndex)
        }
    }

    fileprivate func recede() {
        if !(characterIndex == buffer.startIndex) {
            characterIndex = buffer.index(before: characterIndex)
        }
    }

    fileprivate func advance(_ stride: UInt) {
        stride.times {
            self.advance()
        }
    }

    fileprivate func recede(_ num: UInt) {
        num.times {
            self.recede()
        }
    }
}
