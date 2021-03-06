//
//  Chargeable.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/29/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public typealias Adduct = (group: FunctionalGroup, charge: Int)

public let protonAdduct = Adduct(group: proton, charge: 1)
public let sodiumAdduct = Adduct(group: sodium, charge: 1)
public let ammoniumAdduct = Adduct(group: ammonium, charge: 1)

public protocol Chargeable: Mass {
    var adducts: [Adduct] { get set }
}

extension Chargeable {
    public var charge: Int {
        return adducts.reduce(0) { $0 + $1.charge }
    }
    
    public mutating func setAdducts(type: Adduct, count: Int) {
        adducts = [Adduct](repeating: type, count: count)
    }
    
    public func pseudomolecularIon() -> MassContainer {
        return chargedMass()
    }
    
    public func chargedMass() -> MassContainer {
        let result = calculateMasses()
        
        if adducts.count > 0 {
            let chargedMass = (
                result + adducts.map { $0.group.masses }
                    .reduce(zeroMass) { $0 + $1 }
                ) / adducts.count
            
            return chargedMass - electron.masses // remove one electron mass, for first H+ adduct
        }
        
        return result
    }
}

extension Collection where Element: Chain & Chargeable {
    public func charge(minCharge: Int, maxCharge: Int) -> [Element] {
        return flatMap { sequence in
            (minCharge...maxCharge).map { charge in
                var chargedSequence = sequence
                chargedSequence.adducts.append(contentsOf: repeatElement(protonAdduct, count: charge))

                return chargedSequence
            }
        }
    }
}
