import Foundation

public struct Formula {
    private(set) var elements: [ChemicalElement] = []
    private(set) var _masses: MassContainer = zeroMass

    public var stringValue: String

    public init(stringValue: String) {
        self.stringValue = stringValue
        self.elements = parse(stringValue)
        
        _masses = calculateMasses()
    }

    private typealias ElementInfo = (name: String, count: Int)

    private func parse(_ string: String) -> [ChemicalElement] {
        // https://stackoverflow.com/questions/23602175/regex-for-parsing-chemical-formulas
        let pattern = "([A-Z][a-z]*)([0-9]*)"
//        let pattern =  "([0-9]?d*|[A-Z][a-z]{0,2}?d*)"
//        let pattern = "[+-]?([A-Z][a-z]*)(\\d*)"
//        let openingBrackets = "({["
//        let closingBrackets = ")}]"
        
        var result = [ChemicalElement]()
        
        for match in string.matches(for: pattern) {
            guard let elementString = string.substring(with: match.range),
                let elementInfo = countOneElement(string: String(elementString))
                else { break }
            
            if let element = elementLibrary.first(where: { $0.identifier == elementInfo.name }) {
                for _ in 1...elementInfo.count {
                    result.append(element)
                }
            }
        }
        
        return result
    }
    
    private func countOneElement(string: String) -> ElementInfo? {
        let scanner = Scanner(string: string)
        
        guard
            let element = scanner.scanCharactersFromSet(set: CharacterSet.letters),
            let elementCount = scanner.scanInt()
            else { return nil }
        
        return ElementInfo(element as String, (elementCount == 0) ? 1 : elementCount)
    }
}

extension Formula: Mass {
    public var masses: MassContainer {
        return _masses
    }

    public func calculateMasses() -> MassContainer {
        let result = mass(of: elements)
    
        return stringValue.hasPrefix("-") ? -1 * result : result
    }
}

public let formulaSeparator = " + "

extension Formula {
    public static func + (lhs: Formula, rhs: Formula) -> Formula {
        return Formula(stringValue: (lhs.stringValue + formulaSeparator + rhs.stringValue))
    }

    public static func - (lhs: Formula, rhs: Formula) -> Formula {
        return Formula(stringValue: (lhs.stringValue + formulaSeparator + "-" + rhs.stringValue))
    }
}
