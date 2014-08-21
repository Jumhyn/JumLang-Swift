//
//  Tokens.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 7/26/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

@infix func ==(lhs: Token, rhs: Token) -> Bool {
    switch lhs {
    case .Any:
        return true
    default:
        break
    }
    switch rhs {
    case .Any:
        return true
    default:
        break
    }

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

    case let .Identifier(lid):
        switch rhs {
        case let .Identifier(rid): return lid == rid
        default: return false
        }
    case let .Boolean(lbool):
        switch rhs {
        case let .Boolean(rbool): return lbool == rbool
        default: return false
        }
    case let .Integer(lint):
        switch rhs {
        case let .Integer(rint): return lint == rint
        default: return false
        }
    case let .Decimal(ldouble):
        switch rhs {
        case let .Decimal(rdouble): return ldouble == rdouble
        default: return false
        }
    case let .StringLiteral(lstr):
        switch rhs {
        case let .StringLiteral(rstr): return lstr == rstr
        default: return false
        }
    case let .Type(ltype):
        switch rhs {
        case let .Type(rtype): return ltype == rtype
        default: return false
        }
    default:
        return false
    }
}

enum Token : Streamable, Printable {
    case Any

    case Plus, Minus, Times, Divide
    case Less, LEqual, Equal, GEqual, Greater
    case Not, NEqual
    case Assign
    case And, Or
    case LBrace, RBrace
    case LParen, RParen
    case LBrack, RBrack
    case Colon, Semi

    case If, Else, While, Do, Break, Return

    case Identifier(String)
    case Boolean(Bool)
    case Integer(Int)
    case Decimal(Double)
    case StringLiteral(String)
    case Type(TypeBase)

    case Array, Index

    case Unknown

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

    case .Identifier(let id):
        return "identifier: \(id)"
    case .Boolean(let bool):
        return "boolean: \(bool)"
    case .Integer(let int):
        return "integer: \(int)"
    case .Decimal(let dec):
        return "decimal: \(dec)"
    case .StringLiteral(let str):
        return "string: '\(str)'"
    case .Type(let type):
        return "type: \(type)"

    case .Array, .Index:
        return "array/index operator"

    case .Unknown:
        return "unknown token"
        }
    }

    init(_ value: String) {
        switch value {
        case "+":
            self = .Plus; break
        case "-":
            self = .Minus; break
        case "*":
            self = .Times; break
        case "/":
            self = .Divide; break
        case "<":
            self = .Less; break
        case "<=":
            self = .LEqual; break
        case "==":
            self = .Equal; break
        case ">=":
            self = .GEqual; break
        case ">":
            self = .Greater; break
        case "!":
            self = .Not; break
        case "!=":
            self = .NEqual; break
        case "=":
            self = .Assign; break
        case "&&":
            self = .And; break
        case "||":
            self = .Or; break
        case "{":
            self = .LBrace; break
        case "}":
            self = .RBrace; break
        case "(":
            self = .LParen; break
        case ")":
            self = .RParen; break
        case "[":
            self = .LBrack; break
        case "]":
            self = .RBrack; break

        default:
            self = .Unknown; break
        }
    }
    init (_ value: Character) {
        return self.init(String(value))
    }
    func writeTo<Target : OutputStream>(inout target: Target) {
        target.write(self.description);
    }
}