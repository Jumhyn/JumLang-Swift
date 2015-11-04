//
//  Function.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 1/15/15.
//  Copyright (c) 2015 Jumhyn. All rights reserved.
//

import Foundation

class Prototype : Node {
    var id: Identifier
    var args: [Identifier]

    init(id: Identifier, args: [Identifier], line: UInt) {
        self.id = id
        self.args = args
        super.init(line: line)
    }
}

class Function : Node {
    var signature: Prototype
    var body: Statement

    init(signature: Prototype, body: Statement, line: UInt) {
        self.signature = signature
        self.body = body
        super.init(line: line)
    }

    override func generateLLVMWithGenerator(gen: Generator) {
        var signatureString = "define \(signature.id.type) \(signature.id) ("
        for arg in signature.args {
            signatureString += "\(arg.type) %\(arg.op)"
            if signature.args.indexOf(arg) < signature.args.count-1 {
                signatureString += ","
            }
        }
        signatureString += ") {"
        gen.appendInstruction(signatureString)

        for arg in signature.args {
            gen.appendInstruction("\(arg) = alloca \(arg.type)")
            gen.appendInstruction("store \(arg.type) %\(arg.op), \(arg.type)* \(arg)")
            arg.allocated = true
        }

        let before = gen.reserveLabel(), after = gen.reserveLabel()
        if body.needsBeforeLabel() {
            gen.appendLabel(before)
        }
        body.generateLLVMWithGenerator(gen, beforeLabel: before, afterLabel: after)
        if body.needsAfterLabel() {
            gen.appendLabel(after)
        }
        gen.appendInstruction("}")
    }
}