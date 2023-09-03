//
//  WinType.swift
//  MahjongCalculator (iOS)
//
//  Created by bill on 02.05.21.
//

import Foundation

enum WinType: CaseIterable, Hashable {
    case selfDraw,
         selfDrawPenalty,
         cleanDoor,
         redDragon,
         greenDragon,
         whiteDragon,
         threeGreatScholars,//大三元 TODO: 8 faan, disable 中發白
         threeLesserScholars,//小三元
         flower,
         season,
         east,
         south,
         west,
         north,
         bigFourHappiness,
         smallFourHappiness,
         selfDrawAfterGong,
         selfDrawLastTile,
         allInTriplets,
         commonHand, //平胡
         mixedOneSuit,
         allHonorTiles, //字一色
         allOneSuit,
         robbingAGong, //搶槓
         sevenRobsOne,//七搶一
         flowerKing,// 八仙過海
         fourConcealedTriplets,
         heavenlyHand,
         earthlyHand,
         thirteenOrphans,
         allKongs,
         onlyTerminals //么九
    ///TODO: 九子連環

    static let winds: Set<WinType> = [.east, .west, .north, .south]
    static let dragons: Set<WinType> = [.whiteDragon, .redDragon, .greenDragon]
    static let concealedTriplets: Set<WinType> = [fourConcealedTriplets]
    
    static var windAndDragons: Set<WinType> {
        return Set<WinType>([.threeLesserScholars,
                             .bigFourHappiness, .smallFourHappiness])
        .union(WinType.winds)
        .union(WinType.dragons)
    }
    
    @discardableResult
    private static func addToAdjacencyList(winType: WinType, set: Set<WinType>, list: inout AdjacencyList<WinType>) -> AdjacencyList<WinType> {
        let vertex = list.createVertex(data: winType)
        
        set.forEach() {
            let to = list.createVertex(data: $0)
            
            list.add(from: vertex, to: to)
        }
        
        return list
    }
    
    /// list for inclusive winTypes, if exists 2 vertex have a edge, then they are depends on each other, i.e. when one is non toggled, another is disabled. e.g. not toggled 莊, disable 天胡
    static var dependList: AdjacencyList<WinType> {
        var list = AdjacencyList<WinType>()
        
        let dict: [WinType: Set<WinType>] =
        [
            .selfDraw:[.heavenlyHand, earthlyHand],
        ]
        
        ///TODO: non dealer, non self draw cases?
        
        dict.forEach({ key, value in
            addToAdjacencyList(winType: key,
                               set: value, list: &list)
        })
        
        return list
    }
    
    
    
    /// list for excludive winTypes, if exists 2 vertex have a edge, then they are exclusive, i.e. when one is toggled, another is disabled
    static var adjacencyList: AdjacencyList<WinType> {
        var list = AdjacencyList<WinType>()
        
        /// exclusion pairs, key and value are excluded
        let excludeDict: [WinType: Set<WinType>] =
        [
            .selfDraw: [.robbingAGong],
            .allOneSuit : Set<WinType>([.mixedOneSuit, .allHonorTiles])
            .union(WinType.windAndDragons),
            .allHonorTiles: [.mixedOneSuit],
            .commonHand: Set<WinType>([.flower, .season,
                                       .flowerKing, .sevenRobsOne,
                                       .selfDrawAfterGong,
                                       .allHonorTiles, .allInTriplets,
                                       .fourConcealedTriplets, ]).union(windAndDragons),
            .bigFourHappiness: Set<WinType>([.threeLesserScholars, .smallFourHappiness]).union(WinType.winds),
            .smallFourHappiness: Set<WinType>([.threeLesserScholars]).union(WinType.winds),
            .threeLesserScholars: WinType.dragons,
            .cleanDoor: Set<WinType>([]).union(WinType.concealedTriplets),
            .fourConcealedTriplets: []
        ]
        
        excludeDict.forEach({ key, value in
            addToAdjacencyList(winType: key,
                               set: value, list: &list)
        })
        
        return list
    }
    
    
    /// return true if self is wind win type and wind matches
    /// - Parameter wind: <#wind description#>
    /// - Returns: <#description#>
    private func compareWind(wind: Wind?) -> Bool {
        switch self {
        case .east:
            return wind == .east
        case .south:
            return wind == .south
        case .west:
            return wind == .west
        case .north:
            return wind == .north
        default:
            return false
        }
    }
    
    ///TODO: test for wind
    
    private func isToggled(winTypes: Set<WinType>, dict: [WinType: Bool]) -> Bool {
        return winTypes.contains{ dict[$0] == true }
    }
    
    func seatWindOffset(seatWind: Wind?,
                        dealerWind: Wind?) -> Wind? {
        guard let dealerWind = dealerWind,
              let seatWind = seatWind else { return nil }
        
        return seatWind.seatWind(dealerWind: dealerWind)
    }
    
    private func checkWindButtonDisabled(gameWind: Wind?,
                                         dealerWind: Wind?,
                                         seatWind: Wind?
    ) -> Bool {
        //MARK: check winner wind and is dealer
        /// disable winds other then seat and round wind
        let winnerWind = seatWindOffset(seatWind: seatWind, dealerWind: dealerWind)
        if !compareWind(wind: gameWind),
           !compareWind(wind: winnerWind) {
            return true
        }
        
        return false
    }
    
    /// Win type button is disabled for given conditions
    /// - Returns: ture if the button should be disabled
    func disabled(gameWind: Wind?,
                  seatWind: Wind?,
                  dealerWind: Wind?,
                  isWinnerDealer: Bool,
                  winTypesToggled: [WinType: Bool]
    ) -> Bool {
        guard let gameWind = gameWind,
              let seatWind = seatWind,
              let dealerWind = dealerWind else {
            return false
        }
        
        if self == .selfDrawPenalty {
            return false
        }
        
        if WinType.winds.contains(self) {
            return checkWindButtonDisabled(gameWind: gameWind, dealerWind: dealerWind, seatWind: seatWind)
        }
        
        
        switch (winTypesToggled[.selfDraw], isWinnerDealer, self) {
        case (false, false, .earthlyHand):
            return true
        default:
            break
        }
        
        ///if found self vertex has a edge in toggled destination, return true
        if WinType.dependList.edges(element: self)?.contains(where: {
            winTypesToggled[$0.destination.data] == false
        }) == true {
            return true
        }
        
        
        ///if found self vertex has a edge in toggled destination, return true
        return WinType.adjacencyList.edges(element: self)?.contains(where: {
            winTypesToggled[$0.destination.data] == true
        }) == true
    }
    
    func faan(gameWind: Wind?,
              seatWind: Wind?,
              dealerWind: Wind?,
              allDragonsToggled: Bool,
              isSelfDraw: Bool,
              kongNumber: Int) -> Int {
        switch self {
        case .smallFourHappiness:///todo: enable 清/混一色
            return 6
        case .bigFourHappiness,
                .thirteenOrphans,
                .allKongs,
                .allHonorTiles,
                .heavenlyHand,
                .earthlyHand:
            return 13
        case .cleanDoor:
            return 1
        case .fourConcealedTriplets:
            return 8 ///TODO: 8 + 3 for all triplet, enable all triplet
        case .threeLesserScholars:
            return 4
        case .commonHand:
            return 1
        case .allInTriplets,
                .mixedOneSuit:
            return 3
        case .allOneSuit:
            return 7
        case .sevenRobsOne, .flowerKing:
            return 8
        case .redDragon, .whiteDragon, .greenDragon:
            ///if all 3 matches, 8 faan
            if allDragonsToggled {
                return 6 //大三元/extra 6 faan
            } else {
                return 1
            }
        case .east, .south, .west, .north:
            let seatWindOffset = self.seatWindOffset(seatWind: seatWind, dealerWind: dealerWind)
            if compareWind(wind: gameWind) && compareWind(wind: seatWindOffset) {
                return 2
            } else if compareWind(wind: gameWind) || compareWind(wind: seatWindOffset) {
                return 1
            } else {
                return 0
            }
        case .selfDraw,
                .flower, .season, .selfDrawAfterGong, .selfDrawLastTile,
                .robbingAGong:
            return 1
        case .selfDrawPenalty:
            return Int.min ///TODO
            case .onlyTerminals:
                return 1
        }
    }
    
    func text(gameWind: Wind? = nil,
              seatWind: Wind? = nil) -> String {
        switch self {
        case .selfDraw:
            return "自摸"
            ///TODO: if all three tapped, 8 faan
            ///TODO: idea, tap 1 for 1x,2 for 2x, 3 for 3x
        case .redDragon:
            return "中"
        case .greenDragon:
            return "發"
        case .whiteDragon:
            return "白"
        case .threeLesserScholars:
            return "小三元"
        case .flower:
            switch seatWind {
            case .east:
                return "梅1"
            case .south:
                return "蘭2"
            case .west:
                return "菊3"
            case .north:
                return "竹4"
            case .none:
                return "花"
            }
        case .season:
            switch seatWind {
            case .east:
                return "春1"
            case .south:
                return "夏2"
            case .west:
                return "秋3"
            case .north:
                return "冬4"
            case .none:
                return "季節"
            }
        case .cleanDoor:
            return "門清"
        case .east:
            return "東"
        case .south:
            return "南"
        case .west:
            return "西"
        case .north:
            return "北"
        case .selfDrawAfterGong:
            return "槓上開花"
        case .selfDrawLastTile:
            return "海底撈月"
        case .allInTriplets:
            return "對對胡"
        case .commonHand:
            return "平胡"
        case .mixedOneSuit:
            return "混一色"
        case .allOneSuit: ///TODO: disable when wind/dragons
            return "清一色"
        case .robbingAGong:
            return "搶槓"
        case .sevenRobsOne:
            return "七搶一"
        case .flowerKing:
            return "八仙過海"
        case .fourConcealedTriplets:
            return "四暗刻"
        case .bigFourHappiness:
            return "大四喜"
        case .smallFourHappiness:
            return "小四喜"
        case .allHonorTiles:
            return "字一色"
        case .heavenlyHand:
            return "天胡"
        case .earthlyHand:
            return "地胡"
        case .thirteenOrphans:
            return "十三么"
        case .allKongs:
            return "十八羅漢"
        case .selfDrawPenalty:
            return "包自摸"
            case .onlyTerminals:
                return "么九"
        }
    }
}
