//
//  CarPrediction.swift
//  CoreMLSample
//
//  Created by Dinesh Harjani on 17/06/2017.
//  Copyright © 2017 杨萧玉. All rights reserved.
//

import Foundation

extension Inceptionv3Output {
    
    private static let CarPredictionLabels = [76, 90, 614, 653, 657, 546, 774, 879, 938, 955, 198, 668, 431, 602, 321, 540, 703, 136, 818, 278, 490, 403, 777]
    
    open func isCarPrediction() -> Bool {
        let keysArray = Array(classLabelProbs.keys)
        for labelIndex in Inceptionv3Output.CarPredictionLabels {
            if classLabel == keysArray[labelIndex] {
                return true
            }
        }
        return false
    }
}
