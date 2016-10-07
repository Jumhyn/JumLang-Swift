//
//  Node.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 1/15/15.
//  Copyright (c) 2015 Jumhyn. All rights reserved.
//

import Foundation

protocol LLVMPrintable: TextOutputStreamable {
    func LLVMString() -> String
}

class Node {
    var line: UInt

    init(line: UInt) {
        self.line = line
    }

    func generateLLVM(with gen: Generator) {

    }
}
