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
    var implemented = false

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

    override func generateLLVM(with gen: Generator) {
        var signatureString = "define \(signature.id.type) \(signature.id) ("
        for arg in signature.args {
            signatureString += "\(arg.type) %\(arg.op)"
            if signature.args.index(of: arg)! < signature.args.count-1 {
                signatureString += ","
            }
        }
        signatureString += ") {"
        gen.append(signatureString)

        for arg in signature.args {
            gen.append("\(arg) = alloca \(arg.type)")
            gen.append("store \(arg.type) %\(arg.op), \(arg.type)* \(arg)")
            arg.allocated = true
        }

        let before = gen.reserveLabel(), after = gen.reserveLabel()
        if body.needsBeforeLabel() {
            gen.append(before)
        }
        body.generateLLVM(with: gen, beforeLabel: before, afterLabel: after)
        if body.needsAfterLabel() {
            gen.append(after)
        }
        gen.append("}")
    }
}
