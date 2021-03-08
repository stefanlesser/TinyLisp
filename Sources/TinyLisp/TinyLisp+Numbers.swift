enum Atom {
    case string(String)
    case number(Int)
}

extension Atom: Equatable {}

extension Atom: ExpressibleByIntegerLiteral {
    init(integerLiteral value: IntegerLiteralType) {
        self = .number(value)
    }
}

extension Expr: ExpressibleByIntegerLiteral where AtomType == Atom {
    init(integerLiteral value: IntegerLiteralType) {
        self = .atom(.number(value))
    }
}

extension Atom: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension Atom: CustomStringConvertible {
    var description: String {
        switch self {
        case .string(let string): return string
        case .number(let number): return number.description
        }
    }
}

extension Atom: LosslessStringConvertible {
    init?(_ description: String) {
        self = .string(description)
    }
}

extension Expr where AtomType == Atom {
    static func lowerThan(_ arguments: ArraySlice<Expr>) throws -> Expr {
        guard
            case .atom(.number(let lhs)) = arguments.first,
            case .atom(.number(let rhs)) = arguments.dropFirst().first
        else {
            throw InterpretationError(message: "'<': argument mismatch")
        }
        return lhs < rhs ? true : false
    }

    static func arithmeticOp(_ operation: @escaping (Int, Int) -> Int) -> (ArraySlice<Expr>) throws -> Expr {
        return { arguments in
            guard
                case .atom(.number(let lhs)) = arguments.first,
                case .atom(.number(let rhs)) = arguments.dropFirst().first
            else {
                throw InterpretationError(message: "arithmetic operation: argument mismatch")
            }
            return .atom(.number(operation(lhs, rhs)))
        }
    }
}

struct LispNumbers: Lisp {
    var environment: Expr<Atom>.Environment = [:]

    static var numbersEnvironment: Expr<Atom>.Environment = [
        "<": .function(.builtIn(Expr.lowerThan(_:))),
        "+": .function(.builtIn(Expr.arithmeticOp(+))),
        "-": .function(.builtIn(Expr.arithmeticOp(-))),
        "*": .function(.builtIn(Expr.arithmeticOp(*))),
        "/": .function(.builtIn(Expr.arithmeticOp(/))),
    ]

    init() {
        environment = LispMinimal.basicEnvironment()
        environment.merge(LispBoolean.booleanEnvironment) { a, b in a }
        environment.merge(Self.numbersEnvironment) { a, b in a }
    }
}
