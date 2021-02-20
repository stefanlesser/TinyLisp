enum Expr<AtomType: Equatable & LosslessStringConvertible & ExpressibleByStringLiteral> {
    typealias Environment = [String: Expr]
    typealias Function = ([Expr]) throws -> Expr

    case atom(AtomType)
    indirect case list([Expr])
    case function(Function)
}

extension Expr: Equatable {
    static func == (lhs: Expr, rhs: Expr) -> Bool {
        switch (lhs, rhs) {
        case (.atom(let lhs), .atom(let rhs)):  return lhs == rhs
        case (.list(let lhs), .list(let rhs)):  return lhs == rhs
        default:                                return false
        }
    }
}

extension Expr: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self = .atom(AtomType(value)!) // AtomType conforms to LosslessStringConvertible
    }
}

extension Expr: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Expr...) {
        self = .list(elements)
    }
}

extension Expr: CustomStringConvertible {
    var description: String {
        switch self {
        case .atom(let atom):   return atom.description
        case .list(let list):   return "(\(list.map(\.description).joined(separator: " ")))"
        case .function:         return "<#func>"
        }
    }
}

struct InterpretationError: Error {
    let message: String
}

extension Expr {
    private func apply(_ name: String, _ argumentExpressions: [Expr], _ context: inout Environment) throws -> Expr {
        let argumentValues = try argumentExpressions.map { try $0.eval(in: &context) }
        switch context[name] {
        case .function(let function):   return try function(argumentValues) // built-in function
        case .list(let list):           return try lambda(list, argumentValues, context) // lambda to be evaluated
        case .atom:                     throw InterpretationError(message: "'\(name)' is not executable")
        case .none:                     throw InterpretationError(message: "Undefined symbol: \(name)")
        }
    }

    func eval(in context: inout Environment) throws -> Expr {
        switch self {
        case .atom(let atom):
            return context[atom.description] ?? self // lookup value or pass expression back unchanged
        case .list(let list):
            switch (list.first, list.dropFirst()) {
            case (.none, _):                       return self // empty list (aka nil)
            case (.atom("quote"), let arguments):  return arguments.first! // quote must not eval rest
            case (.atom("if"), let arguments):     return try `if`(Array(arguments), &context)
            case (.atom("label"), let arguments):  return try label(Array(arguments), &context)
            case (.atom(let name), let arguments): return try apply(name.description, Array(arguments), &context) // function call
            case (.list, _),
                 (.function, _):                   throw InterpretationError(message: "First item in list not a symbol")
            }
        case .function:
            throw InterpretationError(message: "Didn't expect a function here")
        }
    }
}

extension Expr { // Special forms
    private func lambda(_ list: [Expr], _ arguments: [Expr], _ context: Environment) throws -> Expr {
        guard
            case .atom("lambda")                = list.first,
            case .list(let argumentExpressions) = list.dropFirst().first,
            let functionBody                    = list.dropFirst(2).first
        else {
            throw InterpretationError(message: "Called apply with unexpected value")
        }

        var newContext: Environment = context
        for (symbol, value) in zip(argumentExpressions, arguments) {
            guard case .atom(let name) = symbol else {
                throw InterpretationError(message: "Argument is not a symbol")
            }
            newContext[name.description] = value
        }
        return try functionBody.eval(in: &newContext)
    }

    private func `if`(_ rest: [Expr], _ context: inout Environment) throws -> Expr {
        guard
            let conditionExpr = rest.first,
            let thenExpr =      rest.dropFirst().first
        else {
            throw InterpretationError(message: "'if': argument mismatch")
        }
        let elseExpr = rest.dropFirst(2).first

        let condition = try conditionExpr.eval(in: &context)
        if case .list([]) = condition { // condition is false (empty list represents nil)
            guard let elseExpr = elseExpr else { return .list([]) } // else is optional
            return try elseExpr.eval(in: &context)
        } else {
            return try thenExpr.eval(in: &context)
        }
    }

    private func label(_ rest: [Expr], _ context: inout Environment) throws -> Expr {
        guard
            case .atom(let name) =  rest.first,
            let valueExpression =   rest.dropFirst().first
        else {
            throw InterpretationError(message: "'label': argument mismatch")
        }

        let value = try valueExpression.eval(in: &context)
        context[name.description] = value
        return value
    }
}

protocol Lisp {
    associatedtype AtomType: Equatable & LosslessStringConvertible & ExpressibleByStringLiteral

    var environment: Expr<AtomType>.Environment { get set }
    mutating func eval(_ expression: Expr<AtomType>) throws -> Expr<AtomType>
}

extension Lisp {
    mutating func eval(_ expression: Expr<AtomType>) throws -> Expr<AtomType> {
        return try expression.eval(in: &environment)
    }
}

extension Lisp {
    mutating func installBuiltIns() {
        let builtIns: Expr<AtomType>.Environment = [
            "car": .function { args in
                guard case .list(let list) = args.first else {
                    throw InterpretationError(message: "'car' expects argument that is a list")
                }
                return list.first!
            },
            "cdr": .function { args in
                guard case .list(let list) = args.first else {
                    throw InterpretationError(message: "'cdr' expects argument that is a list")
                }
                return .list(Array(list.dropFirst()))
            },
            "cons": .function { args in
                guard
                    let element = args.first,
                    case .list(let list) = args.dropFirst().first
                else {
                    throw InterpretationError(message: "'cons': argument mismatch")
                }
                return .list([element] + list)
            },
            "eq": .function { args in
                let (lhs, rhs) = (args.first!, args.dropFirst().first!)
                return lhs == rhs ? .atom("T") : .list([])
            },
            "atom": .function { args in
                if case .atom = args.first! { return .atom("T") } else { return .list([]) }
            },
        ]
        environment = builtIns
    }
}

struct Lisp1: Lisp {
    var environment: Expr<String>.Environment = [:]

    init() {
        installBuiltIns()
    }
}
