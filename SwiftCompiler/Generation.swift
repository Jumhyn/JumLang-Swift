//
//  Generator.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 1/17/15.
//  Copyright (c) 2015 Jumhyn. All rights reserved.
//

import Foundation

typealias Label = UInt

class Generator {
    var currentLabel: UInt = 0
    var output = ""

    func reserveLabel() -> Label {
        return currentLabel++
    }

    func appendLabel(label: Label) {
        output.extendLn("%L\(label):")
    }

    func appendInstruction(code: String) {
        output.extendLn(code)
    }

    func generateLLVMForProgram(program: [Function]) {
        for function in program {
            function.generateLLVMWithGenerator(self)
        }
    }
}