//
//  Tokens.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 7/26/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

enum Token {
    case plus, minus, times, divide
    case less, lEqual, equal, gEqual, greater
    case not, nEqual
    case assign
    case and, or
    case lBrace, rBrace
    case lParen, rParen
    case lBrack, rBrack
    case colon, semi, comma, dot

    case `if`, `else`, `while`, `do`, `break`, `return`, `struct`

    case temp

    case identifier(String)
    case boolean(Bool)
    case integer(Int)
    case decimal(Double)
    case stringLiteral(String)
    case typeName(TypeBase)

    case array, index

    case unknown

    init(_ value: String) {
        switch value {
        case "+":
            self = .plus
        case "-":
            self = .minus
        case "*":
            self = .times
        case "/":
            self = .divide
        case "<":
            self = .less
        case "<=":
            self = .lEqual
        case "==":
            self = .equal
        case ">=":
            self = .gEqual
        case ">":
            self = .greater
        case "!":
            self = .not
        case "!=":
            self = .nEqual
        case "=":
            self = .assign
        case "&&":
            self = .and
        case "||":
            self = .or
        case "{":
            self = .lBrace
        case "}":
            self = .rBrace
        case "(":
            self = .lParen
        case ")":
            self = .rParen
        case "[":
            self = .lBrack
        case "]":
            self = .rBrack
        case ":":
            self = .colon
        case ";":
            self = .semi
        case ",":
            self = .comma
        case ".":
            self = .dot
        default:
            self = .unknown
        }
    }

    init(_ value: Character) {
        self.init(String(value))
    }
}

extension Token : CustomStringConvertible, TextOutputStreamable {
    var description: String {
        switch self {
        case .plus:
            return "+"
        case .minus:
            return "-"
        case .times:
            return "*"
        case .divide:
            return "/"
        case .less:
            return "<"
        case .lEqual:
            return "<="
        case .equal:
            return "=="
        case .gEqual:
            return ">="
        case .greater:
            return ">"
        case .not:
            return "!"
        case .nEqual:
            return "!="
        case .assign:
            return "="
        case .and:
            return "&&"
        case .or:
            return "||"
        case .lBrace:
            return "{"
        case .rBrace:
            return "}"
        case .lParen:
            return "("
        case .rParen:
            return ")"
        case .lBrack:
            return "["
        case .rBrack:
            return "]"
        case .colon:
            return ":"
        case .semi:
            return ";"
        case .comma:
            return ","
        case .dot:
            return "."

        case .if:
            return "if"
        case .else:
            return "else"
        case .while:
            return "while"
        case .do:
            return "do"
        case .break:
            return "break"
        case .return:
            return "return"
        case .struct:
            return "struct"

        case .temp:
            return "t"

        case .identifier(_):
            return "identifier"
        case .boolean(_):
            return "boolean constant"
        case .integer(_):
            return "integer constant"
        case .decimal(_):
            return "floating point constant"
        case .stringLiteral(_):
            return "string literal"
        case .typeName(_):
            return "type"
            
        case .array, .index:
            return "array/index operator"
            
        case .unknown:
            return "unknown token"
        }
    }

    func write<Target : TextOutputStream>(to target: inout Target) {
        target.write(self.LLVMString())
    }
}

extension Token : Hashable {
    var hashValue: Int {
        return self.LLVMString().hashValue
    }
}

extension Token : LLVMPrintable {
    func LLVMString() -> String {
        switch self {
        case .plus:
            return "add"
        case .minus:
            return "sub"
        case .times:
            return "mul"
        case .divide:
            return "div"

        case .equal:
            return "eq"
        case .nEqual:
            return "ne"
        case .less:
            return "lt"
        case .lEqual:
            return "le"
        case .gEqual:
            return "ge"
        case .greater:
            return "gt"

        case .identifier(let id):
            return id
        case .boolean(let bool):
            return bool.description
        case .integer(let int):
            return int.description
        case .decimal(let dec):
            return dec.description
        case .stringLiteral(let str):
            return str
        case .typeName(let type):
            return type.LLVMString()

        default:
            return self.description
        }
    }
}

func ==(lhs: Token, rhs: Token) -> Bool {
    switch (lhs, rhs) {
    case (.plus, .plus): return true
    case (.minus, .minus): return true
    case (.times, .times): return true
    case (.divide, .divide): return true
    case (.less, .less): return true
    case (.lEqual, .lEqual): return true
    case (.equal, .equal): return true
    case (.gEqual, .gEqual): return true
    case (.greater, .greater): return true
    case (.not, .not): return true
    case (.nEqual, .nEqual): return true
    case (.assign, .assign): return true
    case (.and, .and): return true
    case (.or, .or): return true
    case (.lBrace, .lBrace): return true
    case (.rBrace, .rBrace): return true
    case (.lParen, .lParen): return true
    case (.rParen, .rParen): return true
    case (.lBrack, .lBrack): return true
    case (.rBrack, .rBrack): return true
    case (.colon, .colon): return true
    case (.semi, .semi): return true
    case (.comma, .comma): return true
    case (.dot, .dot): return true
    case (.if, .if): return true
    case (.else, .else): return true
    case (.while, .while): return true
    case (.do, .do): return true
    case (.break, .break): return true
    case (.return, .return): return true
    case (.struct, .struct): return true

    case (.identifier(let lhs), .identifier(let rhs)):
        return lhs == rhs
    case (.boolean(let lhs), .boolean(let rhs)):
        return lhs == rhs
    case (.integer(let lhs), .integer(let rhs)):
        return lhs == rhs
    case (.decimal(let lhs), .decimal(let rhs)):
        return lhs == rhs
    case (.stringLiteral(let lhs), .stringLiteral(let rhs)):
        return lhs == rhs
    case (.typeName(let lhs), .typeName(let rhs)):
        return lhs == rhs

    case (.array,  .array): return true
    case (.index, .index): return true

    default: return false
    }
}

extension Token {
    static var anyIdentifier: (_ tok: Token) -> Bool {
        return {
            switch ($0) {
            case .identifier(_):
                return true
            default:
                return false
            }
        }
    }

    static var anyBoolean: (_ tok: Token) -> Bool {
        return {
            switch ($0) {
            case .boolean(_):
                return true
            default:
                return false
            }
        }
    }

    static var anyInteger: (_ tok: Token) -> Bool {
        return {
            switch ($0) {
            case .integer(_):
                return true
            default:
                return false
            }
        }
    }

    static var anyDecimal: (_ tok: Token) -> Bool {
        return {
            switch ($0) {
            case .decimal(_):
                return true
            default:
                return false
            }
        }
    }

    static var anyStringLiteral: (_ tok: Token) -> Bool {
        return {
            switch ($0) {
            case .stringLiteral(_):
                return true
            default:
                return false
            }
        }
    }

    static var anyTypeName: (_ tok: Token) -> Bool {
        return {
            switch ($0) {
            case .typeName(_):
                return true
            default:
                return false
            }
        }
    }
}
