//
//  MassSearch.swift
//  BioSwift
//
//  Created by Koen van der Drift on 4/28/18.
//  Copyright © 2018 Koen van der Drift. All rights reserved.
//

import Foundation

public enum SearchType: Int {
    case sequential
    case unique
    case exhaustive
}

public enum ToleranceType: String {
    case ppm
    case mDa
}

public struct Tolerance {
    public var type: ToleranceType
    public var value: Double
    
    public init(type: ToleranceType, value: Double) {
        self.type = type
        self.value = value
    }
}

public struct SearchParameters {
    public var searchValue: Double
    public var tolerance: Tolerance
    public let searchType: SearchType
    public var charge: Int
    public var massType: MassType
    public let sequenceType: SequenceType
    
    public init(searchValue: Double, tolerance: Tolerance, searchType: SearchType, charge: Int, massType: MassType, sequenceType: SequenceType) {
        self.searchValue = searchValue
        self.tolerance = tolerance
        self.searchType = searchType
        self.charge = charge
        self.massType = massType
        self.sequenceType = sequenceType
    }
    
    func massRange() -> ClosedRange<Double> {
        var minMass = 0.0
        var maxMass = 0.0
        let toleranceValue = Double(tolerance.value)
        
        switch tolerance.type {
        case .ppm:
            let delta = toleranceValue / 1_000_000
            minMass = (1 - delta) * searchValue
            maxMass = (1 + delta) * searchValue
        case .mDa:
            minMass = searchValue - toleranceValue / 1000
            maxMass = searchValue + toleranceValue / 1000
        }
        
        return minMass ... maxMass
    }
}

public typealias SearchResult = Set<String>

public struct MassSearch {
    public let sequence: BioSequence
    public let params: SearchParameters
    
    public init(sequence: BioSequence, params: SearchParameters) {
        self.sequence = sequence
        self.params = params
    }
    
    public func searchMass() -> SearchResult {
        var result = SearchResult()
        guard var symbolSequence = sequence.symbolSequence() else { return result }
        
        let sequenceString = sequence.sequenceString
        
        let range = params.massRange()
        var start = 0
        
        while !symbolSequence.isEmpty {
            var mass = nterm.masses + cterm.masses
            
            // correct way of doing this:
            // get slice of symbolSequence()
            // get pseudomolecular ion
            
            symbolSequence.enumerated().forEach { index, symbol in
                if let symbol = symbol as? Mass, let s = sequenceString.substring(from: start, to: start + index + 1) {
                    mass += symbol.masses
                    let chargedMass = params.charge > 0 ? mass / params.charge : mass
                    
                    switch params.massType {
                    case .monoisotopic:
                        if range.contains(chargedMass.monoisotopicMass) {
                            result.insert(String(s))
                        }
                        
                    case .average:
                        if range.contains(chargedMass.averageMass) {
                            result.insert(String(s))
                        }
                        
                    case .nominal:
                        if range.contains(chargedMass.nominalMass) {
                            result.insert(String(s))
                        }
                    }
                }
            }
            
            symbolSequence.removeFirst()
            start += 1
        }
        
        return result
    }
}
