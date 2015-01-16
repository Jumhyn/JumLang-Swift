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
    var previousScope: Scope?

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
    }

    func identifier(forToken token: Token) -> Identifier! {
        var currentScope = Scope(previousScope: self, globalScope: globalScope)
        while let currentScope = currentScope.previousScope {
            if let ret = symTable[token] {
                return ret
            }
        }
        if let ret = globalScope.symTable[token] {
            return ret
        }
        else if let proto = self.prototype(forToken: token) {
            return proto.id
        }
        return nil
    }

    func set(identifier id: Identifier, forToken token: Token) {
        if let exists = symTable[token] {
            //TODO: error handling...
        }
        else {
            symTable[token] = id
        }
    }

    func prototype(forToken token: Token) -> Prototype! {
        if let proto = globalScope.funcTable[token] {
            return proto
        }
        return nil
    }

    func set(prototype proto: Prototype, forToken token: Token) {
        if let exists = globalScope.funcTable[token] {
            //TODO: error handling...
        }
        else {
            globalScope.funcTable[token] = proto
        }
    }
}