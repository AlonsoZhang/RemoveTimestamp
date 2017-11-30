//
//  ViewController.swift
//  RemoveTimestamp
//
//  Created by Alonso on 2017/11/28.
//  Copyright © 2017年 Alonso. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet var dragView: FileDragView!
    @IBOutlet weak var folderPath: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var showInfo: NSTextView!
    
    var outputlogstr = String()
    var finallogname = ""
    var loglog = ""
    
    var datas = [NSMutableDictionary]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dragView.delegate = self
        self.datas = [
            ["find":"0","ex":"2017/09/13 23:15:17.709972:","regex":"\\d{4}/\\d{1,2}/\\d{1,2} \\d{1,2}:\\d{1,2}:\\d{1,2}\\.\\d{6}:"],
            ["find":"0","ex":"2017-09-13 23:15:39.762 GMT+8 [1234]: ","regex":"\\d{4}-\\d{1,2}-\\d{1,2} \\d{1,2}:\\d{1,2}:\\d{1,2}\\.\\d{3} GMT\\+8 \\[\\d{4}\\]:"],
            ["find":"0","ex":"2017-09-13 23:15:39.762 GMT+8 [12345]: ","regex":"\\d{4}-\\d{1,2}-\\d{1,2} \\d{1,2}:\\d{1,2}:\\d{1,2}\\.\\d{3} GMT\\+8 \\[\\d{5}\\]:"],
            ["find":"1","ex":"[23:16:26.8868]","regex":"\\[\\d{1,2}:\\d{1,2}:\\d{1,2}\\.\\d{4}\\]"],
            ["find":"1","ex":"<DFU Device 0x7f959ac35f00>","regex":"<DFU Device .*?>"]
        ]
        self.tableView.reloadData()
    }
    
    override var representedObject: Any? {
        didSet {
        }
    }
    
    @IBAction func Add(_ sender: NSButton) {
        self.datas.append(["find":"0","regex":""])
        self.tableView.reloadData()
    }
    
    @IBAction func Remove(_ sender: NSButton) {
        let row = tableView.selectedRow
        if row != -1 {
            self.datas.remove(at: row)
            self.tableView.reloadData()
            print("delete row \(row)")
        }else{
            print("No choose line")
        }
    }
    
    @IBAction func Export(_ sender: NSButton) {
        outputlogstr = String()
        loglog = ""
        let url = URL(fileURLWithPath: self.folderPath.stringValue)
        let manager = FileManager.default
        let folderpath =  "\(self.folderPath.stringValue)"
        let patharr: Array = folderpath.components(separatedBy: "/")
        finallogname = patharr[patharr.count - 1]
        print(finallogname)
        var enumeratorAtPath = manager.enumerator(atPath: url.path)
        DispatchQueue.global().async {
//            self.resultDic.removeAll()
//            self.tempDic.removeAll()
            enumeratorAtPath = manager.enumerator(atPath: url.path)
            for logpath in enumeratorAtPath! {
                let truepath = folderpath + "/\(logpath)"
                let tmpData = NSData.init(contentsOfFile: truepath)
                if (tmpData != nil) {
                    let content = String.init(data: tmpData! as Data, encoding: String.Encoding.utf8)
                    if (content != nil) {
                        //print(logpath)
                        self.dealwithlog(log: content!, path: logpath as! String)
                    }else{
                        //self.showmessage(inputString: "No string: \(logpath)")
                    }
                }else{
                    //self.showmessage(inputString: "\n========================================\nFolder: \(logpath)")
                }
            }
            //print(self.loglog)
            let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true) as NSArray
            let creatfile = "\(paths[0])/\(self.finallogname).txt"
            print(creatfile)
            let aaa = "asadas"
            let creatfile2 = "/Users/alonso/Desktop/aaa.txt"
            print(creatfile2)
            do {
                try aaa.write(toFile: creatfile2, atomically: true, encoding: .utf8)
            } catch  {
                print("error2")
                
            }
            do {
                try self.loglog.write(toFile: creatfile, atomically: true, encoding: .utf8)
            } catch  {
                print("error")
                //self.showmessage(inputString: "Error to write txt")
            }
            print(self.loglog)
        }
    }
    
    func dealwithlog(log: String, path: String){
        let patharr: Array = path.components(separatedBy: "/")
        let logname = patharr[patharr.count - 1]
        
        //print(log)
        if !logname.contains(".plist") && log.characters.count > 0 {
            print(logname)
            var finallog = log
            //            let timearray = self.findArrayInString(str: finallog , pattern: "\\d{4}-\\d{1,2}-\\d{1,2} \\d{1,2}:\\d{1,2}:\\d{1,2}\\.\\d{3} GMT\\+8 \\[\\d{4}\\]:")
            //            for time in timearray {
            //                finallog = finallog.replacingOccurrences(of: time, with: "")
            //            }
            //            let timearray2 = self.findArrayInString(str: finallog , pattern: "\\d{4}-\\d{1,2}-\\d{1,2} \\d{1,2}:\\d{1,2}:\\d{1,2}\\.\\d{3} GMT\\+8 \\[\\d{5}\\]:")
            //            for time in timearray2 {
            //                finallog = finallog.replacingOccurrences(of: time, with: "")
            //            }
            //            let timearray3 = self.findArrayInString(str: finallog , pattern: "\\[\\d{1,2}:\\d{1,2}:\\d{1,2}\\.\\d{4}\\]")
            //            for time in timearray3 {
            //                finallog = finallog.replacingOccurrences(of: time, with: "")
            //            }
            finallog = self.findStringInString(str: finallog, pattern: "\\d{4}/\\d{1,2}/\\d{1,2} \\d{1,2}:\\d{1,2}:\\d{1,2}\\.\\d{6}:")
            finallog = self.findStringInString(str: finallog, pattern: "\\d{4}-\\d{1,2}-\\d{1,2} \\d{1,2}:\\d{1,2}:\\d{1,2}\\.\\d{3} GMT\\+8 \\[\\d{4}\\]:")
            finallog = self.findStringInString(str: finallog, pattern: "\\d{4}-\\d{1,2}-\\d{1,2} \\d{1,2}:\\d{1,2}:\\d{1,2}\\.\\d{3} GMT\\+8 \\[\\d{5}\\]:")
            finallog = self.findStringInString(str: finallog, pattern: "\\[\\d{1,2}:\\d{1,2}:\\d{1,2}\\.\\d{4}\\]")
            finallog = self.findStringInString(str: finallog, pattern: "<DFU Device .*?>")
            //            let timearray4 = self.findArrayInString(str: finallog , pattern: "\\d{4}/\\d{1,2}/\\d{1,2} \\d{1,2}:\\d{1,2}:\\d{1,2}\\.\\d{6}:")
            //            for time in timearray4 {
            //                finallog = finallog.replacingOccurrences(of: time, with: "")
            //            }
            //            let timearray5 = self.findArrayInString(str: finallog , pattern: "<DFU Device .*?>")
            //            for time in timearray5 {
            //                finallog = finallog.replacingOccurrences(of: time, with: "")
            //            }
            loglog = "\(loglog)\n\n\(logname)\n\n\(finallog)"
            
        }
    }
    
    func findStringInString(str:String , pattern:String ) -> String
    {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let res2 = regex.stringByReplacingMatches(in: str, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, str.characters.count), withTemplate: "")
            //print(res2)
            //let res = regex.firstMatch(in: str, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, str.characters.count))
            //            if let checkingRes = res2
            //            {
            return ((res2 as NSString).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
            //}
            //return ""
        }
        catch
        {
            //showmessage(inputString: "findStringInString Regex error")
            return ""
        }
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.datas.count
    }
}

extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let data = self.datas[row]
        let key = (tableColumn?.identifier)!
        let value = data[key]
        let view = tableView.makeView(withIdentifier: key, owner: self)
        let subviews = view?.subviews
        if (subviews?.count)!<=0 {
            return nil
        }
        if key.rawValue == "regex" || key.rawValue == "ex"{
            let textField = subviews?[0] as! NSTextField
            if value != nil {
                textField.stringValue = value as! String
            }
        }
        if key.rawValue == "find" {
            let comboField = subviews?[0] as! NSButton
            if value != nil {
                comboField.stringValue = value as! String
            }
        }
        return view
    }
    
    func tableViewSelectionDidChange(_ notification: Notification){
        let tableView = notification.object as! NSTableView
        let row = tableView.selectedRow
        print("selection row \(row)")
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard let rowView = tableView.makeView(withIdentifier:NSUserInterfaceItemIdentifier(rawValue: "RowView"), owner: nil) as! NSTableRowView?
            else {
            let rowView = NSTableRowView()
            rowView.identifier = NSUserInterfaceItemIdentifier(rawValue: "RowView")
            return rowView
        }
        return rowView
    }
}

extension ViewController: FileDragDelegate {
    func didFinishDrag(_ files:Array<Any>){
        if files.count > 1 {
            folderPath.textColor = NSColor.red
            folderPath.stringValue = "Please drag one folder once !!!"
        }else{
            folderPath.textColor = NSColor.blue
            let path = files[0]
            folderPath.stringValue = "\(path)"
        }
    }
}
