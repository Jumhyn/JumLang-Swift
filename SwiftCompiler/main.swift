//
//  main.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 7/25/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

var lex = Lexer(file: "/Users/freddy/Development/Xcode Projects/SwiftCompiler/SwiftCompiler/JumTest.jum")

var parser = Parser(lexer: lex)
var funcs = parser.program()

var gen = Generator()
gen.generateLLVM(for: funcs)
print(gen.output)



//let exitCode = system("clang ")
