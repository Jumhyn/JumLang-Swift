//
//  Expressions.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 8/22/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

class Expression {
    var op: Token
    var type: TypeBase

    init(_ op: Token, _ type: TypeBase) {
        self.op = op
        self.type = type
    }

    func generateRHS() -> Expression {
        return self
    }

    func reduce() -> Expression {
        return self
    }
}

class Identifier : Expression {
    var offset = 0
    var isAllocated = false
    var isArgument = false
    var isGlobal = false
    var enclosingFuncName = ""
    var scopeNumber: UInt = 0

    init(_ op: Token, _ type: TypeBase, offset: Int) {
        self.offset = offset
        super.init(op, type)
    }
}

class Operator : Expression {

}