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

    static var globalScope: Scope = Scope()

    init() {
    }

    init(previousScope: Scope) {
        self.previousScope = previousScope
        Scope.globalScope.scopeCount += 1
    }

    func identifier(for token: Token) -> Identifier? {
        var currentScope: Scope? = self
        while let currentScopeUnwrapped = currentScope {
            if let ret = currentScopeUnwrapped.symTable[token] {
                return ret
            }
            currentScope = currentScopeUnwrapped.previousScope
        }
        if let ret = Scope.globalScope.symTable[token] {
            return ret
        }
        return self.prototype(for: token)?.id
    }

    func set(identifier id: Identifier, forToken token: Token) {
        if let exists = symTable[token] {
            error("attempted to redefine identifier '\(exists.op.LLVMString())' declared on line \(exists.line)", line: id.line)
        }
        else {
            symTable[token] = id
        }
    }

    func prototype(for token: Token) -> Prototype? {
        return Scope.globalScope.funcTable[token]
    }

    func set(prototype proto: Prototype, forToken token: Token) {
        if let exists = Scope.globalScope.funcTable[token] {
            error("attempted to redefine function '\(exists.id.op.LLVMString())' declared on line \(exists.line)", line: proto.line)
        }
        else {
            Scope.globalScope.funcTable[token] = proto
        }
    }

    func type(for token: Token) -> TypeBase? {
        return Scope.globalScope.typeTable[token]
    }

    func set(type: NamedType, forToken token: Token) {
        if let exists = Scope.globalScope.typeTable[token]  {
            error("attempted to redefine type '\(exists.LLVMString())' declared on line \(exists.line)", line: type.line)
        }
        else {
            Scope.globalScope.typeTable[token] = type
        }
    }
}
