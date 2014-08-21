//
//  main.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 7/25/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

var lex = Lexer("+ >= > < <= == - * = + != && || =")

while lex.hasToken() {
    println(lex.nextToken())
}