enum Expr<AtomType: Equatable & LosslessStringConvertible & ExpressibleByStringLiteral> {
    typealias Environment = [String: Expr]

    enum Function {
        case specialForm((ArraySlice<Expr>, inout Environment) throws -> Expr)
        case builtIn((ArraySlice<Expr>) throws -> Expr)
    }

    case atom(AtomType)
    indirect case list(ArraySlice<Expr>)
    case function(Function)
}

extension Expr: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self = .atom(AtomType(value)!) // AtomType conforms to LosslessStringConvertible
    }
}

extension Expr: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Expr...) {
        self = .list(ArraySlice(elements))
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
    private func apply(_ function: Expr, _ arguments: ArraySlice<Expr>, _ context: inout Environment) throws -> Expr {
        switch function {
        case .function(let function): // apply function
            switch function {
            case .specialForm(let specialForm):
                return try specialForm(arguments, &context)
            case .builtIn(let builtIn):
                let evaluatedArguments = ArraySlice(try arguments.map { try $0.eval(in: &context) })
                return try builtIn(evaluatedArguments)
            }
        case .list(let list):
            let evaluatedArguments = ArraySlice(try arguments.map { try $0.eval(in: &context) })
            return try lambda(list, evaluatedArguments, context) // lambda to be evaluated
        case .atom(let name):
            throw InterpretationError(message: "'\(name)' is not executable")
        }
    }

    func eval(in context: inout Environment) throws -> Expr {
        switch self {
        case .function:
            return self
        case .list(let list):
            let function = try list.first!.eval(in: &context)
            return try apply(function, list.dropFirst(), &context)
        case .atom(let atom): // lookup symbol or pass atom back unchanged
            return context[atom.description] ?? self
        }
    }
}

extension Expr { // Special forms
    // TODO: merge into specialForms
    private func lambda(_ list: ArraySlice<Expr>, _ arguments: ArraySlice<Expr>, _ context: Environment) throws -> Expr {
        guard
            case .atom("lambda")                = list.first, // requires AtomType to conform to Equatable
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

    static func quote(_ arguments: ArraySlice<Expr>, _ context: inout Environment) throws -> Expr {
        return arguments.first! // quote must not eval rest
    }

    static func label(_ arguments: ArraySlice<Expr>, _ context: inout Environment) throws -> Expr {
        guard
            case .atom(let name) =  arguments.first,
            let valueExpression =   arguments.dropFirst().first
        else {
            throw InterpretationError(message: "'label': argument mismatch")
        }

        let value = try valueExpression.eval(in: &context)
        context[name.description] = value
        return value
    }

    static func car(_ arguments: ArraySlice<Expr>) throws -> Expr {
        guard case .list(let list) = arguments.first else {
            throw InterpretationError(message: "'car' expects argument that is a list")
        }
        return list.first!
    }

    static func cdr(_ arguments: ArraySlice<Expr>) throws -> Expr {
        guard case .list(let list) = arguments.first else {
            throw InterpretationError(message: "'cdr' expects argument that is a list")
        }
        return .list(list.dropFirst())
    }

    static func cons(_ arguments: ArraySlice<Expr>) throws -> Expr {
        guard
            let element = arguments.first,
            case .list(let list) = arguments.dropFirst().first
        else {
            throw InterpretationError(message: "'cons': argument mismatch")
        }
        return .list([element] + list)
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

struct LispMinimal: Lisp {
    var environment: Expr<String>.Environment = [:]

    static func basicEnvironment<AtomType>() -> Expr<AtomType>.Environment {
        let environment: Expr<AtomType>.Environment = [
            "quote": .function(.specialForm(Expr.quote(_:_:))),
            "label": .function(.specialForm(Expr.label(_:_:))),
            "car": .function(.builtIn(Expr.car(_:))),
            "cdr": .function(.builtIn(Expr.cdr(_:))),
            "cons": .function(.builtIn(Expr.cons(_:))),
        ]
        return environment
    }

    init() {
        environment = Self.basicEnvironment()
    }
}
