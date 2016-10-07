//
//  Parser.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 8/22/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

class Parser {
    var lexer: Lexer

    var lookahead: Token
    var topScope: Scope
    weak var currentFunc: Prototype! = nil

    init(lexer: Lexer) {
        self.lexer = lexer
        self.lookahead = lexer.nextToken()
        self.topScope = Scope.globalScope
    }

    func program() -> Program {
        var funcs: [Function] = []
        while (lookahead == .lBrack) {
            self.match(.lBrack)
            if (lookahead == .struct) {
                self.structure()
            }
            else {
                if let aFunc = self.function() {
                    funcs.append(aFunc)
                }
            }
        }
        let ret = Program(funcs: funcs, globalScope: Scope.globalScope)
        return ret
    }

    func structure() {
        self.match(.struct)
        let name = lookahead
        self.match(Token.anyIdentifier)
        let members = self.argList()
        self.match(.rBrack)
        let type = AggregateType(members: members, name: name, line: lexer.line)
        Scope.globalScope.set(type: type, forToken: name)
    }

    func function() -> Function? {
        let savedScope = topScope
        topScope = Scope(previousScope: savedScope)
        var proto = self.prototype()
        if let exists = Scope.globalScope.prototype(for: proto.id.op) {
            if exists.implemented {
                error("attempt to redefine function \(proto) declared on line \(proto.id.line)", line: lexer.line)
            }
            else {
                proto = exists
            }
        }
        else {
            Scope.globalScope.set(prototype: proto, forToken: proto.id.op)
        }

        if lookahead == .lBrace {
            self.match(.lBrace)
            currentFunc = proto
            if let stmt = self.sequence() {
                self.match(.rBrace)
                topScope = savedScope
                proto.implemented = true
                return Function(signature: proto, body: stmt, line: lexer.line)
            }
            else {
                error("expected statement", line: lexer.line)
            }
        }
        return nil
    }

    func prototype() -> Prototype {
        //get the return type of the function
        let funcType = self.type()

        //get the identifier
        let funcIdTok = lookahead
        self.match(Token.anyIdentifier)

        var args: [Identifier] = []
        //if there are arguments, get them
        if lookahead == .colon {
            args = self.argList()
        }
        self.match(.rBrack)

        //create the identifier for the function and return the prototype
        let funcId = Identifier(op: funcIdTok, type: funcType, line: lexer.line)
        funcId.isGlobal = true
        return Prototype(id: funcId, args: args, line: lexer.line)
    }

    func argList() -> [Identifier] {
        var args: [Identifier] = []
        self.match(.colon)
        repeat {
            let varType = self.type()
            let varIdTok = lookahead
            self.match(Token.anyIdentifier)

            let id = Identifier(op: varIdTok, type: varType, line: lexer.line)
            id.isArgument = true
            args.append(id)
            topScope.set(identifier: id, forToken: varIdTok)

            //if we are done, exit the loop
            if lookahead == .rBrack {
                break
            }
            //otherwise, match a comma and possibly exit
            self.match(.comma)
        } while (Token.anyTypeName(lookahead))
        return args
    }

    func type() -> TypeBase {
        //match a type token and return the corresponding type
        switch lookahead {
        case .typeName(var type):
            self.match(Token.anyTypeName)
            while lookahead == .lBrack {
                self.match(.lBrack)
                switch lookahead {
                case .integer(let val):
                    self.match(Token.anyIdentifier)
                    type = ArrayType(numElements: UInt(val), to: type)
                    self.match(.rBrack)
                case .rBrack:
                    self.match(.rBrack)
                    type = ArrayType(numElements: 0, to: type)
                default:
                    error("expected array type declaration", line: lexer.line)
                }
            }
            return type
        case .identifier(_):
            if let type = Scope.globalScope.type(for: lookahead) {
                self.match(Token.anyIdentifier)
                return type
            }
            fallthrough
        default:
            error("expected type name", line: lexer.line)
        }
    }

    func match(_ token: Token) {
        //match a specific token
        match {$0 == token}
    }

    func matchOneOf(_ tokens: Token ...) {
        //match any one of multiple tokens
        match {tokens.contains($0)}
    }

    func match(_ condition: (Token) -> Bool) {
        if (condition(lookahead)) {
            lookahead = lexer.nextToken()
        }
        else {
            error("found \(lookahead)", line: lexer.line)
        }
    }
}

//MARK: - Statements
extension Parser {
    func statement() -> Statement {
        switch lookahead {
        case .if:
            return self.ifStatement()
        case .while:
            return self.whileStatement()
        case .do:
            return self.doWhileStatement()
        case .return:
            return self.returnStatement()
        case .typeName,
             .identifier(_) where Scope.globalScope.type(for: lookahead) != nil:
            return self.declaration()
        case .lBrack:
            //the beginning of a call
            let expr = self.callExpression()
            return Expratement(expr: expr, line: lexer.line)
        case .lBrace:
            return self.block()
        case .identifier:
            return self.assignment()
        default:
            error("expected statement", line: lexer.line)
        }
    }

    func declaration() -> Statement {
        //a type indicates either a array or variable declaration
        let type = self.type()
        if let type = type as? ArrayType {
            return self.arrayDeclaration(of: type)
        }
        else {
            return self.variableDeclaration(of: type)
        }
    }

    func variableDeclaration(of type: TypeBase) -> Statement {
        let idTok = lookahead
        self.match(Token.anyIdentifier)
        let id = Identifier(op: idTok, type: type, line: lexer.line)
        id.enclosingFuncName = currentFunc.id.op.LLVMString()
        id.scopeNumber = Scope.globalScope.scopeCount
        topScope.set(identifier: id, forToken: idTok)

        switch lookahead {
        case .semi:
            self.match(.semi)
            return self.statement()
        case .assign:
            self.match(.assign)
            let expr = self.orExpression()
            self.match(.semi)
            return Assignment(id: id, expr: expr, line: lexer.line)
        default:
            error("expected variable declaration", line: lexer.line)
        }
    }

    func arrayDeclaration(of type: ArrayType) -> Statement {
        let idTok = lookahead
        self.match(Token.anyIdentifier)
        let id = Identifier(op: idTok, type: type, line: lexer.line)
        id.enclosingFuncName = currentFunc.id.op.LLVMString()
        id.scopeNumber = Scope.globalScope.scopeCount
        topScope.set(identifier: id, forToken: idTok)
        if lookahead == .assign {
            self.match(.assign)
            let expr = self.arrayLiteral()
            //let numElements = (expr.type as? ArrayType)?.numElements ?? error("array literal must have array type", line: lexer.line);
            if !validate(type, againstQualified: expr.type as! ArrayType) {
                error("array literal and declaration must agree in number of elements", line: lexer.line)
            }
            else {
                self.match(.semi)
                return Assignment(id: id, expr: expr, line: lexer.line)
            }
        }
        //TODO: check that array type is fully qualified (if there is no literal)
        else {
            self.match(.semi)
            return Assignment(id: id, expr: type.defaultConstant(), line: lexer.line)
        }
    }

    func validate(_ declared: ArrayType, againstQualified actual: ArrayType) -> Bool {
        if declared.numElements == 0 {
            declared.numElements = actual.numElements
        }
        if declared.numElements != actual.numElements {
            return false
        }
        else {
            if let declared = declared.to as? ArrayType, let actual = actual.to as? ArrayType {
                return validate(declared, againstQualified: actual)
            }
            if actual.to.canConvert(to: declared.to) { //TODO: fix bug for converting sizes e.g. int to char
                return true
            }
            return false
        }
    }

    func block() -> Statement {
        //a block is just a sequence with its own scope
        self.match(.lBrace)

        //save the current scope and create a new one
        topScope = Scope(previousScope: topScope)
        if let stmt = self.sequence() {
            self.match(.rBrace)

            //restore the scope
            topScope = topScope.previousScope!
            return stmt
        }
        error("expected statement", line: lexer.line)
    }

    func sequence() -> Statement? {
        if lookahead == .rBrace {
            return nil
        }
        else {
            return Sequence(stmt1: self.statement(), stmt2Opt: self.sequence(), line: lexer.line)
        }
    }

    func ifStatement() -> If {
        self.match(.if)
        let expr = self.expression()
        if !(expr is Logical) {
            error("expected expression with boolean result", line: lexer.line)
        }
        let stmt = self.statement()
        if self.lookahead == .else {
            self.match(.else)
            return If(expr: expr as! Logical, stmt: stmt, elseStmt: self.statement(), line: lexer.line)
        }
        return If(expr: expr as! Logical, stmt: stmt, line: lexer.line)
    }

    func whileStatement() -> While {
        self.match(.while)
        let expr = self.expression()
        if !(expr is Logical) {
            error("expected expression with boolean result", line: lexer.line)
        }
        return While(expr: expr as! Logical, stmt: self.statement(), line: lexer.line)
    }

    func doWhileStatement() -> DoWhile {
        self.match(.do)
        let stmt = self.statement()
        self.match(.while)
        let expr = self.expression()
        if !(expr is Logical) {
            error("expected expression with boolean result", line: lexer.line)
        }
        self.match(.semi)
        return DoWhile(stmt: stmt, expr: expr as! Logical, line: lexer.line)
    }

    func returnStatement() -> Return {
        self.match(.return)
        if lookahead == .semi {
            self.match(.semi)
            return Return(from: currentFunc, line: lexer.line)
        }
        if currentFunc.id.type == TypeBase.voidType() {
            error("returning value from void function", line: lexer.line)
        }
        let expr = self.orExpression()
        self.match(.semi)
        return Return(expr: expr, from: currentFunc, line: lexer.line)
    }

    func assignment() -> Assignment {
        let id = self.identifier()
        self.match(.assign)
        let stmt = Assignment(id: id, expr: self.orExpression(), line: lexer.line)
        self.match(.semi)
        return stmt
    }
}

//MARK: - Expressions

extension Parser {
    func expression() -> Expression {
        switch lookahead {
        case .lParen:
            self.match(.lParen)
            let expr = self.orExpression()
            self.match(.rParen)
            return expr
        case .integer(_),.decimal(_),.boolean(_):
            return self.constantExpression()
        case .lBrack:
            return self.callExpression()
        case .identifier(_):
            return self.identifier()
        default:
            error("expected expression", line: lexer.line)
        }
    }

    func orExpression() -> Expression {
        var lhs = self.andExpression()
        while lookahead == .or {
            self.match(.or)
            let rhs = self.andExpression()
            if !(lhs is Logical && rhs is Logical) {
                error("expected expression with boolean result", line: lexer.line)
            }
            lhs = Or(expr1: lhs as! Logical, expr2: rhs as! Logical, line: lexer.line)
        }
        return lhs
    }

    func andExpression() -> Expression {
        var lhs = self.equalityExpression()
        while lookahead == .and {
            self.match(.and)
            let rhs = self.equalityExpression()
            if !(lhs is Logical && rhs is Logical) {
                error("expected expression with boolean result", line: lexer.line)
            }
            lhs = And(expr1: lhs as! Logical, expr2: rhs as! Logical, line: lexer.line)
        }
        return lhs
    }

    func equalityExpression() -> Expression {
        var lhs = self.inequalityExpression()
        while lookahead == .equal || lookahead == .nEqual {
            let op = lookahead
            self.matchOneOf(.equal, .nEqual)
            let rhs = self.inequalityExpression()
            lhs = Relation(op: op, expr1: lhs, expr2: rhs, line: lexer.line)
        }
        return lhs
    }

    func inequalityExpression() -> Expression {
        var lhs = self.additionExpression()
        while lookahead == .less || lookahead == .lEqual || lookahead == .greater || lookahead == .gEqual {
            let op = lookahead
            self.matchOneOf(.less, .lEqual, .greater, .gEqual)
            let rhs = self.additionExpression()
            lhs = Relation(op: op, expr1: lhs, expr2: rhs, line: lexer.line)
        }
        return lhs
    }

    func additionExpression() -> Expression {
        var lhs = self.multiplicationExpression()
        while lookahead == .plus || lookahead == .minus {
            let op = lookahead
            self.matchOneOf(.plus, .minus)
            let rhs = self.multiplicationExpression()
            lhs = Arithmetic(op: op, expr1: lhs, expr2: rhs, line: lexer.line)
        }
        return lhs
    }

    func multiplicationExpression() -> Expression {
        var lhs = self.unaryExpression()
        while lookahead == .times || lookahead == .divide {
            let op = lookahead
            self.matchOneOf(.times, .divide)
            let rhs = self.unaryExpression()
            lhs = Arithmetic(op: op, expr1: lhs, expr2: rhs, line: lexer.line)
        }
        return lhs
    }

    func unaryExpression() -> Expression {
        if lookahead == .minus {
            self.match(.minus)
            switch lookahead {
            case .integer(let val):
                return Constant(intVal: -val, line: lexer.line)
            case .decimal(let val):
                return Constant(floatVal: -val, line: lexer.line)
            default:
                let expr = self.unaryExpression()
                if expr is Unary && expr.op == .minus {
                    return (expr as! Unary).expr
                }
                return Unary(op: .minus, expr: expr, line: lexer.line)
            }
        }
        else if lookahead == .not {
            self.match(.not)
            let expr = self.unaryExpression()
            if !(expr is Logical) {
                error("expected expression with boolean result", line: lexer.line)
            }
            return Not(op: .not, expr: expr as! Logical, line: lexer.line)
        }
        else {
            return self.expression()
        }
    }

    func callExpression() -> Expression {
        self.match(.lBrack)
        let idTok = lookahead
        let id = self.identifier()
        var args: [Expression] = []
        if let signature = Scope.globalScope.prototype(for: idTok) {
            if signature.args.count > 0 {
                self.match(.colon)
                while (true) {
                    let expr = self.orExpression()
                    args.append(expr)
                    if lookahead == .rBrack {
                        break
                    }
                    self.match(.comma)
                }
            }
            self.match(.rBrack)
            return Call(id: id, args: args, signature: signature, line: lexer.line)
        }
        else {
            error("use of undecalred identifier \(idTok)", line: lexer.line)
        }
    }

    func identifier() -> Identifier {
        let idTok = lookahead
        if var id = topScope.identifier(for: idTok) {
            self.match(Token.anyIdentifier)
            if lookahead == .lBrack {
                let exprs: [Expression] = self.accesses(id)
                for expr in exprs {
                    if id.type is ArrayType {
                        id = ArrayAccess(indexExpr: expr, arrayId: id, line: lexer.line)
                    }
                    else {
                        id = MemberAccess(member: expr, parent: id, line: lexer.line)
                    }
                }
            }
            return id
        }
        else {
            error("use of undecalred identifier \(idTok)", line: lexer.line)
        }
    }

    func accesses(_ id: Identifier) -> [Expression] {
        var type = id.type
        var exprs: [Expression] = []
        while lookahead == .lBrack {
            var indexExprs: [Expression] = []
            while let arr = type as? ArrayType , lookahead == .lBrack {
                self.match(.lBrack)
                let expr = self.orExpression()
                indexExprs.append(expr)
                type = arr.to
                self.match(.rBrack)
            }
            exprs.append(contentsOf: indexExprs.reversed())
            while let agg = type as? AggregateType , lookahead == .lBrack {
                self.match(.lBrack)
                let idTok = lookahead
                self.match(Token.anyIdentifier)
                if let member = agg.getMember(withName: idTok) {
                    exprs.append(member)
                    type = member.type
                    self.match(.rBrack)
                }
                else {
                    error("no member \(idTok) found in type \(type)", line: lexer.line)
                }
            }
        }
        return exprs
    }

    func constantExpression() -> Constant {
        switch lookahead {
        case .integer(let val):
            self.match(Token.anyInteger)
            return Constant(intVal: val, line: lexer.line)
        case .decimal(let val):
            self.match(Token.anyDecimal)
            return Constant(floatVal: val, line: lexer.line)
        case .boolean(let val):
            self.match(Token.anyBoolean)
            return BooleanConstant(boolVal: val, line: lexer.line)
        case .lBrack:
            return self.arrayLiteral()
        default:
            error("expected constant", line: lexer.line)
        }
    }

    func arrayLiteral() -> ArrayLiteral {
        switch lookahead {
        case .lBrack:
            self.match(.lBrack)
            var values: [Constant] = []
            while true {
                let const = self.constantExpression()
                values.append(const)
                if lookahead != .comma {
                    break
                }
                self.match(.comma)
            }
            self.match(.rBrack)
            return ArrayLiteral(values: values, line: lexer.line)
        case .stringLiteral(let str):
            let charArray = str.utf8CString
            var values: [Constant] = []
            for c in charArray {
                values.append(Constant(intVal: Int(c), line: lexer.line))
            }
            self.match(Token.anyStringLiteral)
            return ArrayLiteral(values: values, line: lexer.line)
        default:
            error("expected array or string literal", line: lexer.line)
        }
    }
}

func error(_ err: String, line: UInt) -> Never  {
    fatalError("near line \(line): \(err)");
}
