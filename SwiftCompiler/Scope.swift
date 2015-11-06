//
//  Scope.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 1/15/15.
//  Copyright (c) 2015 Jumhyn. All rights reserved.
//

import Foundation

class Scope {
    var symTable: [Token : Identifier] = [:]
    var funcTable: [Token : Prototype] = [:]
    var typeTable: [Token : NamedType] = [:]
    var scopeCount: UInt = 0
    var previousScope: Scope? = nil

    unowned var globalScope: Scope

    convenience init(previousScope: Scope) {
        self.init(previousScope: previousScope, globalScope: self)
    }

    convenience init() {
        self.init(globalScope: self)
    }

    init(globalScope: Scope) {
        self.globalScope = globalScope
    }

    init(previousScope: Scope, globalScope: Scope) {
        self.previousScope = previousScope
        self.globalScope = globalScope
        self.globalScope.scopeCount++
    }

    func identifierForToken(token: Token) -> Identifier? {
        for (var currentScope: Scope? = self; currentScope != nil; currentScope = currentScope?.previousScope) {
            if let ret = symTable[token] {
                return ret
            }
        }
        if let ret = globalScope.symTable[token] {
            return ret
        }
        return self.prototypeForToken(token)?.id
    }

    func setIdentifier(id: Identifier, forToken token: Token) {
        if let exists = symTable[token] {
            error("attempted to redefine identifier '\(exists.op.LLVMString())' declared on line \(exists.line)", line: id.line)
        }
        else {
            symTable[token] = id
        }
    }

    func prototypeForToken(token: Token) -> Prototype? {
        return globalScope.funcTable[token]
    }

    func setPrototype(proto: Prototype, forToken token: Token) {
        if let exists = globalScope.funcTable[token] {
            error("attempted to redefine function '\(exists.id.op.LLVMString())' declared on line \(exists.line)", line: proto.line)
        }
        else {
            globalScope.funcTable[token] = proto
        }
    }

    func typeForToken(token: Token) -> TypeBase? {
        return globalScope.typeTable[token]
    }

    func setType(type: NamedType, forToken token: Token) {
        if let exists = globalScope.typeTable[token]  {
            error("attempted to redefine type '\(exists.LLVMString())' declared on line \(exists.line)", line: type.line)
        }
        else {
            globalScope.typeTable[token] = type
        }
    }
}