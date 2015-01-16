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
    var previousScope: Scope

    unowned var globalScope: Scope

    convenience init(previousScope: Scope) {
        self.init(previousScope: previousScope, globalScope: self)
    }

    init(previousScope: Scope, globalScope: Scope) {
        self.previousScope = previousScope
        self.globalScope = globalScope
    }
}