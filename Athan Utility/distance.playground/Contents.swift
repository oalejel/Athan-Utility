//: Playground - noun: a place where people can play

import UIKit
import SceneKit


enum Player: Int {
    case P1, P2, None
}
var currentPlayer = Player.P1


var currentPlayerMatrix = Array(count: 3, repeatedValue: Array(count: 3, repeatedValue: Array(count: 3, repeatedValue: false)))

currentPlayerMatrix[0][0][1] = true
currentPlayerMatrix[0][0][2] = true
currentPlayerMatrix[0][2][0] = true
currentPlayerMatrix[0][2][1] = true
currentPlayerMatrix[0][2][2] = true
currentPlayerMatrix[1][1][1] = true
currentPlayerMatrix[1][1][2] = true
currentPlayerMatrix[1][2][0] = true
currentPlayerMatrix[1][2][2] = true



var positionsArray: [(x: Int, y: Int, z: Int)] = []
///get all possible tuples...
for x in 0...2 {
    for y in 0...2 {
        for z in 0...2 {
            if currentPlayerMatrix[x][y][z] {
                positionsArray.append((x, y, z))//append the boolean
            }
        }
    }
}




let endIndex = (positionsArray.count - 1)
for (index, tuple) in positionsArray.enumerate() {
    if (index + 1) >= endIndex {break}
    let test1Slice = positionsArray[(index + 1)...endIndex]
    for (index2, tuple2) in test1Slice.enumerate() {
        if index2 + 1 >= endIndex {break}
        let test2Slice = positionsArray[(index2 + 1)...endIndex]
        for tuple3 in test2Slice {
            
            let mx1 = tuple2.x - tuple.x
            let mx2 = tuple3.x - tuple2.x
            
            let my1 = tuple2.y - tuple.y
            let my2 = tuple3.y - tuple2.y
            
            let mz1 = tuple2.z - tuple.z
            let mz2 = tuple3.z - tuple2.z
            
            var pointsOfVerity = 0
            var oneOrTwoDontChange = false
            
            if mx1 == mx2 {
                if mx1 == 0 && mx2 == 0 {
                    oneOrTwoDontChange = true
                }
                pointsOfVerity++
            }
            
            if my1 == my2 {
                if my1 == 0 && my2 == 0 {
                    oneOrTwoDontChange = true
                }
                pointsOfVerity++
            }
            
            if mz1 == mz2 {
                if mz1 == 0 && mz2 == 0 {
                    oneOrTwoDontChange = true
                }
                pointsOfVerity++
            }
            
            if pointsOfVerity == 3 {
                print("ok")
            }
            
        }
    }
}



//
//let endIndex = (positionsArray.count - 1)
//for (index, tuple) in positionsArray.enumerate() {
//    if (index + 1) >= endIndex {break}
//    let test1Slice = positionsArray[(index + 1)...endIndex]
//    for (index2, tuple2) in test1Slice.enumerate() {
//        if index2 + 1 >= endIndex {break}
//        let test2Slice = positionsArray[(index2 + 1)...endIndex]
//        for tuple3 in test2Slice {
//            
//            let mx1 = tuple2.x - tuple.x
//            let mx2 = tuple3.x - tuple2.x
//            print(mx1)
//            
//            let my1 = tuple2.y - tuple.y
//            let my2 = tuple3.y - tuple2.y
//            print(my1)
//            
//            let mz1 = tuple2.z - tuple.z
//            let mz2 = tuple3.z - tuple2.z
//            print(mz2)
//            //get changes in change, if it is 0 for all, then it works?
//            
//        }
//    }
//}




//
//
//var boolArray: [Bool] = []
/////get all possible tuples...
//for x in 0...2 {
//    for y in 0...2 {
//        for z in 0...2 {
//            boolArray.append(currentPlayerMatrix[x][y][z])//append the boolean
//        }
//    }
//}
//
//var positions: [Int] = []
//for (index, b) in boolArray.enumerate() {
//    //do the complex tuple check
//    if b == true {
//        positions.append(index)
//    }
//}
//
//for (index1, p1) in positions.enumerate() {
//    if (index1 + 1) >= (positions.count - 1) {break }
//    let slice1 = positions[(index1 + 1)...(positions.count - 1)]
//    for (index2, p2) in slice1.enumerate() {
//        let d1 = p2 - p1
//        if d1 == 1 || d1 == 3 || d1 == 6 || d1 == 9 {
//            if (index2 + 1) >= (positions.count - 1) {break }
//            let slice2 = positions[(index2 + 1)...(positions.count - 1)]
//            for p3 in slice2 {
//                let d2 = p3 - p2
//                if d2 == 1 || d2 == 3 || d2 == 6 || d2 == 9 {
//                    if d1 == d2 {
//                    }
//                }
//            }
//        }
//    }
//}
//
//positions
//
//boolArray


