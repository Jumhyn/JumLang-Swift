//
//  main.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 7/25/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

println("Hello, World!")

//let bundle = NSBundle.mainBundle()
//let path = bundle.pathForResource("JumTest", ofType: "jum")
//
//var tok1 = Token.Minus
//var tok2 = Token.Plus
//
//var cmp = tok1 == tok2
//
//println("\(cmp)")
//
//var lex = Lexer(path)
//
//var thing = Array("hi")

var lex = Lexer(string: "+ >= > < <= == - * = + != && || =")

println(lex.nextToken())
println(lex.nextToken())
println(lex.nextToken())
println(lex.nextToken())
println(lex.nextToken())
println(lex.nextToken())
println(lex.nextToken())
println(lex.nextToken())
println(lex.nextToken())
println(lex.nextToken())
println(lex.nextToken())
println(lex.nextToken())
println(lex.nextToken())