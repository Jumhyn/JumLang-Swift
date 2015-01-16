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
        //a program is an array of functions
        var ret: [Function] = []
        while (lookahead == .LBrack) {
            ret.append(self.function())
        }
        return ret
    }

    func function() -> Function {
        var savedScope = topScope
        topScope = Scope(previousScope: savedScope, globalScope: globalScope)
        var proto = self.prototype()
        currentFunc = proto
        globalScope.setPrototype(proto, forToken: proto.id.op)
        self.match(.LBrace)
        var stmt = self.sequence()
        self.match(.RBrace)
        topScope = savedScope
        if let stmtUnwrapped = stmt {
            return Function(proto,stmtUnwrapped)
        }
        error("expected statement", lexer.line)
    }

    func prototype() -> Prototype {
        self.match(.LBrack)
        //get the return type of the function
        var funcType = self.type()

        //get the identifier
        var funcIdTok = lookahead
        self.match(.Identifier(nil))

        var args: [Identifier] = []
        //if there are arguments, get them
        if lookahead == .Colon {
            self.match(.Colon)
            do {
                var varType = self.type()
                var varIdTok = lookahead
                self.match(.Identifier(nil))

                var id = Identifier(varIdTok, type: varType, offset: 0)
                args.append(id)
                topScope.setIdentifier(id, forToken: varIdTok)

                //if we are done, exit the loop
                if lookahead == .RBrack {
                    break
                }
                //otherwise, match a comma and possibly exit
                self.match(.Comma)
            } while (lookahead == .Type(nil))
        }
        self.match(.RBrack)

        //create the identifier for the function and return the prototype
        var funcId = Identifier(funcIdTok, type: funcType, offset: 0)
        return Prototype(funcId, args)
    }

    func type() -> TypeBase {
        switch lookahead {
        case .Type(let type):
            return type!
        default:
            error("expected type", lexer.line)
        }
    }

    func sequence() -> Statement? {
        if lookahead == .RBrace {
            return nil
        }
        else {
            return Sequence(stmt1: self.statement(), stmt2Opt: self.sequence())
        }
    }

    func statement() -> Statement {
        return Statement()
    }

    func match(token: Token) {
        if (lookahead == token || token == .Any) {
            lookahead = lexer.nextToken()
        }
        else {
            error("expected \(token) instead of \(lookahead)", lexer.line)
        }
    }

}