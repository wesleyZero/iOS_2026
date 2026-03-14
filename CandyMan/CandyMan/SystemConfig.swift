//
//  SystemConfig.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import Foundation
import SwiftUI

struct MoldSpec {
    var shape: GummyShape
    var count: Int
    var volume_ml: Double

    init(_ shape : GummyShape, _ count: Int, _ volume_ml: Double){
        self.shape = shape
        self.count = count
        self.volume_ml = volume_ml
    }

}



@Observable
class SystemConfig{
    var bear = MoldSpec(.bear, 22, 2.339)
    var star = MoldSpec(.star, 22, 2.211)
    var cloud = MoldSpec(.cloud, 22, 2.182)
    var circle = MoldSpec(.circle, 22, 2.292)

    func setSpec(_ spec: MoldSpec, for shape: GummyShape) {
        switch shape {
        case .bear:   bear = spec
        case .star:   star = spec
        case .cloud:  cloud = spec
        case .circle: circle = spec
        }
    }

    func spec(for shape: GummyShape) -> MoldSpec {
        switch shape {
        case .bear:   return bear
        case .star:   return star
        case .cloud:  return cloud
        case .circle: return circle
        }
    }

}
