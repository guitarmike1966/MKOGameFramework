//
//  GameBoardClasses.swift
//  MKOGameFramework
//
//  Created by Michael O'Connell on 5/8/20.
//  Copyright © 2020 Michael O'Connell. All rights reserved.
//

import Foundation
import Cocoa

extension NSColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexFormatted: String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()

        if hexFormatted.hasPrefix("#") {
            hexFormatted = String(hexFormatted.dropFirst())
        }

        assert(hexFormatted.count == 6, "Invalid hex code used.")

        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)

        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                  alpha: alpha)
    }

    static let darkGreen = NSColor(hex: "005000")
    static let lightGreen = NSColor(hex: "40FF40")
    static let darkBlue = NSColor(hex: "000090")
}


public enum GameBoardCellTerrain {
    case Woods
    case Grass
    case Desert
    case Tundra
    case Mountain
    case Water
    case Other

    public func toColor() -> NSColor {
        switch self {
        case .Grass:
            return NSColor.lightGreen
        case .Woods:
            return NSColor.darkGreen
        case .Desert:
            return NSColor.yellow
        case .Tundra:
            return NSColor.white
        case .Mountain:
            return NSColor.darkGray
        case .Water:
            return NSColor.darkBlue
        default:
            return NSColor.blue
        }
    }
    
    public func toString() -> String {
        switch self {
            case .Grass:
                return "Grass"
            case .Woods:
                return "Woods"
            case .Desert:
                return "Desert"
            case .Tundra:
                return "Tundra"
            case .Mountain:
                return "Mountain"
            case .Water:
                return "Water"
            default:
                return "Other"
        }
    }
}


public class GameBoardCell {
    var terrain: GameBoardCellTerrain
    public var selected: Bool
    public var view: HexView
    
    public var canSelect: Bool {
        get {
            switch self.terrain {
            case .Grass:
                    return true
            case .Woods:
                    return true
            case .Desert:
                    return true
            case .Water:
                    return true
            default:
                    return false
            }
        }

    }

    init(terrain: GameBoardCellTerrain, cellHeight: CGFloat) {
        self.terrain = terrain
        self.selected = false
        self.view = HexView(frame: NSRect(x: 0, y: 0, width: CellWidth, height: CellHeight))

        self.view.color = terrain.toColor()

        deselectCell()
    }

    public func selectCell() {
        self.selected = true
        self.view.selected = true
        self.view.display()
    }

    public func deselectCell() {
        self.selected = false
        self.view.selected = false
        self.view.display()
    }

    public func setTerrain(terrain: GameBoardCellTerrain) {
        self.terrain = terrain
        self.view.color = terrain.toColor()
        self.view.display()
    }

}


public class GameBoardRow {
    public var cells: [GameBoardCell]

    init(initialRow: [GameBoardCellTerrain], cellHeight: CGFloat) {
        self.cells = []

        for x in 0..<initialRow.count {
            self.cells.append(GameBoardCell(terrain: initialRow[x], cellHeight: cellHeight))
        }
    }

    init(cols: Int, cellHeight: CGFloat) {
        self.cells = []

        for _ in 0..<cols {
            self.cells.append(GameBoardCell(terrain: .Grass, cellHeight: cellHeight))
        }
    }
}


public class GameBoard {
    public var rows: [GameBoardRow]
    public var CellHeight: CGFloat
    public var CellWidth: CGFloat
    public var path: String = ""

    public init(initialBoard: [[GameBoardCellTerrain]], cellHeight: CGFloat) {
        self.rows = []

        CellHeight = cellHeight
        CellWidth = cellHeight * 0.866

        for y in 0..<initialBoard.count {
            self.rows.append(GameBoardRow(initialRow: initialBoard[y], cellHeight: cellHeight))
        }
    }


    public init(rows: Int, cols: Int, cellHeight: CGFloat) {
        self.rows = []

        CellHeight = cellHeight
        CellWidth = cellHeight * 0.866

        for _ in 0..<rows {
            self.rows.append(GameBoardRow(cols: cols, cellHeight: cellHeight))
        }
    }


    public func clearHighlight() {
        for y in 0..<rows.count {
            for x in 0..<rows[y].cells.count {
                if rows[y].cells[x].selected {
                    rows[y].cells[x].deselectCell()
                }
            }
        }
    }


//    func highlightCell(x: Int, y: Int) {
//        rows[y].cells[x].selectCell()
//    }


    public func OpenFile(path: String) -> Bool {
        var retval = false

        do {
            var data = try String(contentsOfFile: path)

            print("JSON data read:")
            print("\(data)")

            let decoder = JSONDecoder()
 
            let jsonData = data.data(using: .utf8)!
            let jsonBoard = try decoder.decode(JSONBoard.self, from: jsonData)

            print("Successfully decoded JSON data")

            for y in 0..<self.rows.count {

                for x in 0..<self.rows[0].cells.count {
                    var terrain = GameBoardCellTerrain.Grass

                    switch jsonBoard.row[y].cell[x].Terrain {
                    case "Grass" : terrain = .Grass
                    case "Woods" : terrain = .Woods
                    case "Water" : terrain = .Water
                    case "Desert" : terrain = .Desert
                    case "Mountain" : terrain = .Mountain
                    case "Tundra" : terrain = .Tundra
                    default : terrain = .Other
                    }

                    self.rows[y].cells[x].terrain = terrain
                    self.rows[y].cells[x].view.color = terrain.toColor()
                    self.rows[y].cells[x].view.display()
                }
            }

            retval = true
        }
        catch {
            print("Open JSON file error: \(error)")
        }
        

        print("OpenFile function is not fully implemented yet in Framework")

        return retval
    }


    public func SaveFile(path: String, type: String) -> Bool {
        var retval = false

        if type == "XML" {
            retval = SaveXMLFile(path: path)
        }
        else {
            retval = SaveJSONFile(path: path)
        }

        return retval
    }


    private func SaveJSONFile(path: String) -> Bool {
        var retval = false

        // build JSONOutput data
        
        var jsonBoard = JSONBoard(rows: self.rows.count, cols: self.rows[0].cells.count, row: [])
        
        for y in 0..<self.rows.count {
            
            let newRow = JSONRow(cell: [])
            jsonBoard.row.append(newRow)
            
            for x in 0..<self.rows[y].cells.count {
                let newCell = JSONCell(Terrain: self.rows[y].cells[x].terrain.toString())
                jsonBoard.row[y].cell.append(newCell)
            }
        }

        // write JSONEncoder

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(jsonBoard)
            print("\nResulting JSON")
            print(String(data: data, encoding: .utf8)!)

            let fileURL = URL(fileURLWithPath: path)
            do {
                try data.write(to: fileURL, options: .atomic)
            }
            catch {
                print("Write JSON error: \(error)")
            }
        }
        catch {
            print("\(error)")
        }

        return retval
    }


    private func SaveXMLFile(path: String) -> Bool {
        var retval = false

        let fileMgr = FileManager.default

        if !fileMgr.fileExists(atPath: path) {
            fileMgr.createFile(atPath: path, contents: "".data(using: .utf8), attributes: nil)
        }

        let fileHandle = FileHandle(forWritingAtPath: path)

        if fileHandle != nil {

            SaveXMLLine(fileHandle: fileHandle!, line: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>")

            SaveXMLBoard(fileHandle: fileHandle!)

            fileHandle!.closeFile()

            retval = true
        }
        else {
            print("File open failed")
        }

        return retval
    }


    private func SaveXMLBoard(fileHandle: FileHandle) {
        SaveXMLLine(fileHandle: fileHandle, line: "<Board>")

        for y in 0..<self.rows.count {
            SaveXMLRow(fileHandle: fileHandle, row: y)
        }

        SaveXMLLine(fileHandle: fileHandle, line: "</Board>")
    }


    private func SaveXMLRow(fileHandle: FileHandle, row: Int)  {
        SaveXMLLine(fileHandle: fileHandle, line: "  <Row>")

        for x in 0..<self.rows[row].cells.count {
            SaveXMLCell(fileHandle: fileHandle, row: row, cell: x)
        }

        SaveXMLLine(fileHandle: fileHandle, line: "  </Row>")
    }


    private func SaveXMLCell(fileHandle: FileHandle,row: Int, cell: Int) {

        SaveXMLLine(fileHandle: fileHandle, line: "    <Cell>")

//        var Terrain = ""

//        switch (self.rows[row].cells[cell].terrain) {
//        case .Grass: Terrain = "Grass"
//        case .Woods: Terrain = "Woods"
//        case .Water: Terrain = "Water"
//        case .Desert: Terrain = "Desert"
//        case .Mountain: Terrain = "Mountain"
//        case .Tundra: Terrain = "Tundra"
//        default: Terrain = "Other"
//        }

        SaveXMLLine(fileHandle: fileHandle, line: "      <Terrain>\(self.rows[row].cells[cell].terrain.toString())</Terrain>")

        SaveXMLLine(fileHandle: fileHandle, line: "    </Cell>")
    }


    private func SaveXMLLine(fileHandle: FileHandle, line: String) {
        // print("    Starting line")
        let lineCRLF = line + "\n"

        let data = lineCRLF.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))

        fileHandle.write(data!)
    }

}



struct JSONCell: Codable {
    var Terrain : String
}

struct JSONRow: Codable {
    var cell : [JSONCell]
}

struct JSONBoard: Codable {
    var rows : Int
    var cols : Int
    var row : [JSONRow]
}


//private class JSONInputCell: Decodable {
//    var Terrain : String
//}
//
//private class JSONInputRow: Decodable {
//    var cell : [JSONInputCell]
//}
//
//private class JSONInputBoard: Decodable {
//    var rows : Int
//    var cols : Int
//    var row : [JSONInputRow]
//}
