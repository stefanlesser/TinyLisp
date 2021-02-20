enum Atom {
    case string(String)
    case number(Int)
}

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

extension Atom: Equatable {}

extension Lisp where AtomType == Atom {
    mutating func installNumberBuiltIns() {
        let numberBuiltIns: [String: Expr<Atom>.Function] = [
            "<": .builtIn { args in
                guard
                    case .atom(.number(let lhs)) = args.first,
                    case .atom(.number(let rhs)) = args.dropFirst().first
                else {
                    throw InterpretationError(message: "'<': argument mismatch")
                }
                return lhs < rhs ? true : false
            },
            "+": .builtIn { args in
                guard
                    case .atom(.number(let lhs)) = args.first,
                    case .atom(.number(let rhs)) = args.dropFirst().first
                else {
                    throw InterpretationError(message: "'+': argument mismatch")
                }
                return .atom(.number(lhs + rhs))
            },
            "-": .builtIn { args in
                guard
                    case .atom(.number(let lhs)) = args.first,
                    case .atom(.number(let rhs)) = args.dropFirst().first
                else {
                    throw InterpretationError(message: "'-': argument mismatch")
                }
                return .atom(.number(lhs - rhs))
            },
        ]
        
        for (key, value) in numberBuiltIns.mapValues({ Expr<AtomType>.function($0) }) {
            environment[key] = value
        }
    }
}

struct Lisp2: Lisp {
    var environment: Expr<Atom>.Environment = [:]

    init() {
        installBuiltIns()
        installNumberBuiltIns()
    }
}
