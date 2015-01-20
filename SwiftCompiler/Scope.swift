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

    func identifierForToken(token: Token) -> Identifier {
        for (var currentScope: Scope? = self; currentScope != nil; currentScope = currentScope?.previousScope) {
            if let ret = symTable[token] {
                return ret
            }
        }
        if let ret = globalScope.symTable[token] {
            return ret
        }
        return self.prototypeForToken(token).id
    }

    func setIdentifier(id: Identifier, forToken token: Token) {
        if let exists = symTable[token] {
            //TODO: error handling...
        }
        else {
            symTable[token] = id
        }
    }

    func prototypeForToken(token: Token) -> Prototype {
        if let proto = globalScope.funcTable[token] {
            return proto
        }
        error("use of undeclared identifier", 0)
    }

    func setPrototype(proto: Prototype, forToken token: Token) {
        if let exists = globalScope.funcTable[token] {
            //TODO: error handling...
        }
        else {
            globalScope.funcTable[token] = proto
        }
    }
}