//
//  Parser.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 8/22/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

class Parser {
    var lexer: Lexer

    var lookahead: Token
    var globalScope: Scope
    var topScope: Scope
    weak var currentFunc: Prototype? = nil

    init(_ lexer: Lexer) {
        self.lexer = lexer
        self.lookahead = lexer.nextToken()
        self.globalScope = Scope()
        self.topScope = self.globalScope
    }

    func program() -> [Function] {
        var ret: [Function] = []
        do {
            if (lookahead == .LBrack) {
                ret.append(self.function())
            }
        } while (lookahead == .LBrack)
        return ret
    }

    func function() -> Function {
        var savedScope = topScope
        topScope = Scope(previousScope: savedScope, globalScope: globalScope)
        var proto = self.prototype()
        return Function(proto, self.statement())
    }

    func prototype() -> Prototype {
        self.match(.LBrack)
        var funcType = self.type()
        var funcIdTok = lookahead
        self.match(.Identifier("any"))

        var args: [Identifier] = []
        if lookahead == .Colon {
            self.match(.Colon)
            do {
                var varType = self.type()
                var varIdTok = lookahead
                self.match(.Identifier("any"))

                var id = Identifier(varIdTok, type: varType, offset: 0)
                args.append(id)
                topScope.setIdentifier(id, forToken: varIdTok)

                if lookahead == .RBrack {
                    break
                }
                self.match(.Comma)
            } while (lookahead.matches(.Type(TypeBase(false, 0))))
        }
        self.match(.RBrack)
        var funcId = Identifier(funcIdTok, type: funcType, offset: 0)
        return Prototype(funcId, args)
    }

    func type() -> TypeBase! {
        switch lookahead {
        case .Type(let type):
            return type
        default:
            error("expected type", lexer.line)
            return nil
        }
    }

    func match(token: Token) {
        if (lookahead.matches(token) || token == .Any) {
            lookahead = lexer.nextToken()
        }
        else {
            error("expected \(token) instead of \(lookahead)", lexer.line)
        }
    }

    func statement() -> Statement {
        return Statement()
    }
}