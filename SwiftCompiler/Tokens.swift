//
//  Tokens.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 7/26/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

func ==(lhs: Token, rhs: Token) -> Bool {
    switch lhs {
    case .Plus:
        switch rhs {
        case .Plus: return true
        default: return false
        }
    case .Minus:
        switch rhs {
        case .Minus: return true
        default: return false
        }
    case .Times:
        switch rhs {
        case .Times: return true
        default: return false
        }
    case .Divide:
        switch rhs {
        case .Divide: return true
        default: return false
        }

    case .Less:
        switch rhs {
        case .Less: return true
        default: return false
        }
    case .LEqual:
        switch rhs {
        case .LEqual: return true
        default: return false
        }
    case .Equal:
        switch rhs {
        case .Equal: return true
        default: return false
        }
    case .GEqual:
        switch rhs {
        case .GEqual: return true
        default: return false
        }
    case .Greater:
        switch rhs {
        case .Greater: return true
        default: return false
        }

    case .Not:
        switch rhs {
        case .Not: return true
        default: return false
        }
    case .NEqual:
        switch rhs {
        case .NEqual: return true
        default: return false
        }

    case .Assign:
        switch rhs {
        case .Assign: return true
        default: return false
        }

    case .And:
        switch rhs {
        case .And: return true
        default: return false
        }
    case .Or:
        switch rhs {
        case .Or: return true
        default: return false
        }

    case .LBrace:
        switch rhs {
        case .LBrace: return true
        default: return false
        }
    case .RBrace:
        switch rhs {
        case .RBrace: return true
        default: return false
        }
    case .LParen:
        switch rhs {
        case .LParen: return true
        default: return false
        }
    case .RParen:
        switch rhs {
        case .RParen: return true
        default: return false
        }
    case .LBrack:
        switch rhs {
        case .LBrack: return true
        default: return false
        }
    case .RBrack:
        switch rhs {
        case .RBrack: return true
        default: return false
        }

    case .Colon:
        switch rhs {
        case .Colon: return true
        default: return false
        }
    case .Semi:
        switch rhs {
        case .Semi: return true
        default: return false
        }
    case .Comma:
        switch rhs {
        case .Comma: return true
        default: return false
        }
    case .Dot:
        switch rhs {
        case .Dot: return true
        default: return false
        }

    case .If:
        switch rhs {
        case .If: return true
        default: return false
        }
    case .Else:
        switch rhs {
        case .Else: return true
        default: return false
        }
    case .While:
        switch rhs {
        case .While: return true
        default: return false
        }
    case .Do:
        switch rhs {
        case .Do: return true
        default: return false
        }
    case .Break:
        switch rhs {
        case .Break: return true
        default: return false
        }
    case .Return:
        switch rhs {
        case .Return: return true
        default: return false
        }

    case let .Identifier(lid):
        switch rhs {
        case let .Identifier(rid):
            if (lid == nil || rid == nil) {
                return true
            }
            return lid == rid
        default: return false
        }
    case let .Boolean(lbool):
        switch rhs {
        case let .Boolean(rbool):
            if (lbool == nil || rbool == nil) {
                return true
            }
            return lbool == rbool
        default: return false
        }
    case let .Integer(lint):
        switch rhs {
        case let .Integer(rint):
            if (lint == nil || rint == nil) {
                return true
            }
            return lint == rint
        default: return false
        }
    case let .Decimal(ldouble):
        switch rhs {
        case let .Decimal(rdouble):
            if (ldouble == nil || rdouble == nil) {
                return true
            }
            return ldouble == rdouble
        default: return false
        }
    case let .StringLiteral(lstr):
        switch rhs {
        case let .StringLiteral(rstr):
            if (lstr == nil || rstr == nil) {
                return true
            }
            return lstr == rstr
        default: return false
        }
    case let .Type(ltype):
        switch rhs {
        case let .Type(rtype):
            if (ltype == nil || rtype == nil) {
                return true
            }
            return rtype == ltype
        default: return false
        }

    case .Array:
        switch rhs {
        case .Array: return true
        default: return false
        }
    case .Index:
        switch rhs {
        case .Index: return true
        default: return false
        }

    case .Any:
        switch rhs {
        case .Any: return true
        default: return false
        }
        
    default:
        return false
    }
}

enum Token {
    case Any

    case Plus, Minus, Times, Divide
    case Less, LEqual, Equal, GEqual, Greater
    case Not, NEqual
    case Assign
    case And, Or
    case LBrace, RBrace
    case LParen, RParen
    case LBrack, RBrack
    case Colon, Semi, Comma, Dot

    case If, Else, While, Do, Break, Return

    case Temp

    //associated values are optional types so that
    //(for example) .Identifier(nil) will match *any*
    //.Identifier token
    case Identifier(String?)
    case Boolean(Bool?)
    case Integer(Int?)
    case Decimal(Double?)
    case StringLiteral(String?)
    case Type(TypeBase?)

    case Array, Index

    case Unknown

    init(_ value: String) {
        switch value {
        case "+":
            self = .Plus
        case "-":
            self = .Minus
        case "*":
            self = .Times
        case "/":
            self = .Divide
        case "<":
            self = .Less
        case "<=":
            self = .LEqual
        case "==":
            self = .Equal
        case ">=":
            self = .GEqual
        case ">":
            self = .Greater
        case "!":
            self = .Not
        case "!=":
            self = .NEqual
        case "=":
            self = .Assign
        case "&&":
            self = .And
        case "||":
            self = .Or
        case "{":
            self = .LBrace
        case "}":
            self = .RBrace
        case "(":
            self = .LParen
        case ")":
            self = .RParen
        case "[":
            self = .LBrack
        case "]":
            self = .RBrack
        case ":":
            self = .Colon
        case ";":
            self = .Semi
        case ",":
            self = .Comma
        case ".":
            self = .Dot

        default:
            self = .Unknown
        }
    }

    init (_ value: Character) {
        self.init(String(value))
    }
}

extension Token : CustomStringConvertible, Streamable {
    var description: String {
        switch self {
        case .Any:
            return "wildcard"

        case .Plus:
            return "+"
        case .Minus:
            return "-"
        case .Times:
            return "*"
        case .Divide:
            return "/"
        case .Less:
            return "<"
        case .LEqual:
            return "<="
        case .Equal:
            return "=="
        case .GEqual:
            return ">="
        case .Greater:
            return ">"
        case .Not:
            return "!"
        case .NEqual:
            return "!="
        case .Assign:
            return "="
        case .And:
            return "&&"
        case .Or:
            return "||"
        case .LBrace:
            return "{"
        case .RBrace:
            return "}"
        case .LParen:
            return "("
        case .RParen:
            return ")"
        case .LBrack:
            return "["
        case .RBrack:
            return "]"
        case .Colon:
            return ":"
        case .Semi:
            return ";"
        case .Comma:
            return ","
        case .Dot:
            return "."

        case .If:
            return "if"
        case .Else:
            return "else"
        case .While:
            return "while"
        case .Do:
            return "do"
        case .Break:
            return "break"
        case .Return:
            return "return"

        case .Temp:
            return "t"

        case .Identifier(_):
            return "identifier"
        case .Boolean(_):
            return "boolean constant"
        case .Integer(_):
            return "integer constant"
        case .Decimal(_):
            return "floating point constant"
        case .StringLiteral(_):
            return "string literal"
        case .Type(_):
            return "type"
            
        case .Array, .Index:
            return "array/index operator"
            
        case .Unknown:
            return "unknown token"
        }
    }

    func writeTo<Target : OutputStreamType>(inout target: Target) {
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
        case .Plus:
            return "add"
        case .Minus:
            return "sub"
        case .Times:
            return "mul"
        case .Divide:
            return "div"

        case .Equal:
            return "eq"
        case .NEqual:
            return "ne"
        case .Less:
            return "lt"
        case .LEqual:
            return "le"
        case .GEqual:
            return "ge"
        case .Greater:
            return "gt"

        case .Identifier(let id):
            return id ?? "identifier"
        case .Boolean(let bool):
            return bool?.description ?? "boolean"
        case .Integer(let int):
            return int?.description ?? "integer literal"
        case .Decimal(let dec):
            return dec?.description ?? "floating point literal"
        case .StringLiteral(let str):
            return str ?? "string literal"
        case .Type(let type):
            return type?.LLVMString() ?? "type expression"

        default:
            return self.description
        }
    }
}