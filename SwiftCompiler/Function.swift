//
//  Function.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 1/15/15.
//  Copyright (c) 2015 Jumhyn. All rights reserved.
//

import Foundation

class Prototype {
    var id: Identifier
    var args: [Identifier]

    init(_ id: Identifier, _ args: [Identifier]) {
        self.id = id
        self.args = args
    }
}

class Function {
    var signature: Prototype
    var body: Statement

    init(_ signature: Prototype, _ body: Statement) {
        self.signature = signature
        self.body = body
    }
}