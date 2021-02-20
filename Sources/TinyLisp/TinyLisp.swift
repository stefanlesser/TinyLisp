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

extension Expr: Equatable {
    static func == (lhs: Expr, rhs: Expr) -> Bool {
        switch (lhs, rhs) {
        case (.atom(let lhs), .atom(let rhs)):  return lhs == rhs
        case (.list(let lhs), .list(let rhs)):  return lhs == rhs
        default:                                return false
        }
    }
}

extension Expr: ExpressibleByBooleanLiteral {
    init(booleanLiteral value: BooleanLiteralType) {
        self = .atom(value == false ? "nil" : "T") // only place that defines which Expr represent true and false
    }
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
            return specialForms[atom.description] ?? context[atom.description] ?? self
        }
    }
}

extension Expr { // Special forms
    var specialForms: [String: Expr] {
        [
            "quote": .function(.specialForm { arguments, _ in
                return arguments.first! // quote must not eval rest
            }),
            "if": .function(.specialForm { arguments, context in
                guard
                    let conditionExpr = arguments.first,
                    let thenExpr =      arguments.dropFirst().first
                else {
                    throw InterpretationError(message: "'if': argument mismatch")
                }
                let elseExpr = arguments.dropFirst(2).first

                let condition = try conditionExpr.eval(in: &context)
                if condition == false { // possible through ExpressibleByBooleanLiteral conformance
                    guard let elseExpr = elseExpr else { return false } // else is optional
                    return try elseExpr.eval(in: &context)
                } else {
                    return try thenExpr.eval(in: &context)
                }
            }),
            "label": .function(.specialForm { arguments, context in
                guard
                    case .atom(let name) =  arguments.first,
                    let valueExpression =   arguments.dropFirst().first
                else {
                    throw InterpretationError(message: "'label': argument mismatch")
                }

                let value = try valueExpression.eval(in: &context)
                context[name.description] = value
                return value
            })
        ]
    }

    private func lambda(_ list: ArraySlice<Expr>, _ arguments: ArraySlice<Expr>, _ context: Environment) throws -> Expr {
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
        let builtIns: [String: Expr<AtomType>.Function] = [
            "car": .builtIn { args in
                guard case .list(let list) = args.first else {
                    throw InterpretationError(message: "'car' expects argument that is a list")
                }
                return list.first!
            },
            "cdr": .builtIn { args in
                guard case .list(let list) = args.first else {
                    throw InterpretationError(message: "'cdr' expects argument that is a list")
                }
                return .list(list.dropFirst())
            },
            "cons": .builtIn { args in
                guard
                    let element = args.first,
                    case .list(let list) = args.dropFirst().first
                else {
                    throw InterpretationError(message: "'cons': argument mismatch")
                }
                return .list([element] + list)
            },
            "eq": .builtIn { args in
                let (lhs, rhs) = (args.first!, args.dropFirst().first!)
                return lhs == rhs ? true : false
            },
            "atom": .builtIn { args in
                if case .atom = args.first! { return true } else { return false }
            },
        ]
        environment = builtIns.mapValues { Expr<AtomType>.function($0) }
    }
}

struct Lisp1: Lisp {
    var environment: Expr<String>.Environment = [:]

    init() {
        installBuiltIns()
    }
}
