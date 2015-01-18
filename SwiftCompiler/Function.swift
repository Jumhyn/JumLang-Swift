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

class Function : Statement {
    var signature: Prototype
    var body: Statement

    init(_ signature: Prototype, _ body: Statement) {
        self.signature = signature
        self.body = body
    }

    override func generateLLVM(gen: Generator) {
        var signatureString = "define \(self.signature.id.type.LLVMString()) \(self.signature.id.LLVMString()) ("
        for arg in self.signature.args {
            signatureString.extend("\(arg.type.LLVMString()) %\(arg.op.LLVMString())")
            if find(self.signature.args, arg) < self.signature.args.count {
                signatureString.extend(",")
            }
        }
        signatureString.extend(") {")
        gen.appendInstruction(signatureString)
    }
}