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
    @IBOutlet var detailInfo: NSTextView!
    @IBOutlet weak var errorInfo: NSTextField!
    @IBOutlet weak var txtBtn: NSButton!
    @IBOutlet weak var logBtn: NSButton!
    @IBOutlet weak var csvBtn: NSButton!
    @IBOutlet weak var plistBtn: NSButton!
    
    var file = ""
    var ConfigPlist = [String: Any]()
    var loglog = ""
    var datas = [NSMutableDictionary]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dragView.delegate = self
        file = Bundle.main.path(forResource:"Config", ofType: "plist")!
        ConfigPlist = NSDictionary(contentsOfFile: file)! as! [String : Any]
        self.datas = ConfigPlist["Regex"] as! [NSMutableDictionary]
        self.tableView.reloadData()
    }
    
    override var representedObject: Any? {
        didSet {
        }
    }
    
    @IBAction func fileFormat(_ sender: NSButton) {
        print(sender.title)
    }
    
    
    @IBAction func Add(_ sender: NSButton) {
        self.datas.append(["find":"0","regex":""])
        self.tableView.reloadData()
    }
    
    @IBAction func Remove(_ sender: NSButton) {
        errorInfo.stringValue = ""
        let row = tableView.selectedRow
        if row != -1 {
            self.datas.remove(at: row)
            self.tableView.reloadData()
            print("delete row \(row)")
        }else{
            errorInfo.stringValue = "No choose line"
        }
    }
    
    @IBAction func Refresh(_ sender: NSButton) {
    }
    
    @IBAction func Save(_ sender: NSButton) {
    }
    
    @IBAction func Export(_ sender: NSButton) {
        errorInfo.stringValue = ""
        self.detailInfo.string = ""
        loglog = ""
        let url = URL(fileURLWithPath: self.folderPath.stringValue)
        let manager = FileManager.default
        let folderpath =  "\(self.folderPath.stringValue)"
        if folderpath.count == 0 {
            errorInfo.stringValue = "No folder find"
            return
        }
        let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true) as NSArray
        let patharr: Array = folderpath.components(separatedBy: "/")
        let foldername = patharr.last!
        var enumeratorAtPath = manager.enumerator(atPath: url.path)
        for logpath in enumeratorAtPath! {
            if (logpath as! String).contains(".logarchive"){
                self.run(cmd: "rm -rf \(folderpath)/\(logpath)")
            }
        }
        print(paths[0])
        self.run(cmd: "cp -R \(folderpath) \(paths[0])/new\(foldername)")
        enumeratorAtPath = manager.enumerator(atPath: url.path)
        let fileFlagArr:Array = [txtBtn.stringValue == "1" ? "txt" : "",logBtn.stringValue == "1" ? "log" : "",csvBtn.stringValue == "1" ? "csv" : "",plistBtn.stringValue == "1" ? "plist" : ""]
        DispatchQueue.global().async {
            for logpath in enumeratorAtPath! {
                let truepath = folderpath + "/\(logpath)"
                let newpath = "\(paths[0])/new\(foldername)/\(logpath)"
                let logstylearr: Array = (logpath as! String).components(separatedBy: ".")
                if logstylearr.count > 1 && fileFlagArr.contains(logstylearr.last!){
                    let tmpData = NSData.init(contentsOfFile: truepath)
                    if (tmpData != nil) {
                        let content = String.init(data: tmpData! as Data, encoding: String.Encoding.utf8)
                        if (content != nil) {
                            var finallog = content!
                            for eachRegex in self.datas{
                                if eachRegex["find"] as! String == "0"{
                                    finallog = self.replaceStringInString(str: finallog, pattern: eachRegex["regex"] as! String, replacewith: "")
                                }else if eachRegex["find"] as! String == "1"{
                                    finallog = self.findStringInString(str: finallog, pattern: eachRegex["regex"] as! String)
                                }else{
                                    self.errorInfo.stringValue = "Error config find format"
                                }
                            }
                            do {
                                try finallog.write(toFile: newpath, atomically: true, encoding: .utf8)
                            } catch  {
                                self.showmessage(inputString: "Error to write at \(newpath)")
                            }
                        }else{
                            self.showmessage(inputString: "No string: \(logpath)")
                            self.run(cmd: "rm -rf \(newpath)")
                        }
                    }else{
                        self.run(cmd: "rm -rf \(newpath)")
                    }
                }else{
                    var isDir:ObjCBool = true
                    manager.fileExists(atPath: truepath, isDirectory: &isDir)
                    if !isDir.boolValue{
                        //print("\(paths[0])/\(logpath)")
                        self.run(cmd: "rm -rf \(newpath)")
                    }
                }
            }
        }
    }
    
    func findStringInString(str:String , pattern:String ) -> String
    {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let res = regex.firstMatch(in: str, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, str.count))
            if let checkingRes = res
            {
                return ((str as NSString).substring(with: checkingRes.range)).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            return ""
        }
        catch
        {
            showmessage(inputString: "findStringInString Regex error")
            return ""
        }
    }
    
    func replaceStringInString(str:String , pattern:String ,replacewith:String ) -> String
    {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let res = regex.stringByReplacingMatches(in: str, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, str.count), withTemplate: replacewith)
            return ((res as NSString).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
        }
        catch
        {
            showmessage(inputString: "findStringInString Regex error")
            return ""
        }
    }
    
    func showmessage(inputString: String) {
        DispatchQueue.main.async {
            if self.detailInfo.string == "" {
                self.detailInfo.string = inputString
            }else{
                self.detailInfo.string = self.detailInfo.string + "\n\(inputString)"
            }
        }
    }
    
    func run(cmd:String) {
        var error: NSDictionary?
        NSAppleScript(source: "do shell script \"\(cmd)\"")!.executeAndReturnError(&error)
        if error != nil {
            showmessage(inputString: "\(String(describing: error))")
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
