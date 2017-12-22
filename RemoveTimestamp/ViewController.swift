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
    @IBOutlet weak var processbar: NSProgressIndicator!
    @IBOutlet weak var processLabel: NSTextField!
    @IBOutlet weak var exportBtn: NSButton!
    var file = ""
    var ConfigPlist = [String: Any]()
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
        self.datas = ConfigPlist["Regex"] as! [NSMutableDictionary]
        self.tableView.reloadData()
    }
    
    @IBAction func Save(_ sender: NSButton) {
        ConfigPlist["Regex"] = self.datas
        NSDictionary(dictionary: ConfigPlist).write(toFile: file, atomically: true)
        showmessage(inputString: "Save successful\n")
    }
    
    @IBAction func Export(_ sender: NSButton) {
        errorInfo.stringValue = ""
        self.detailInfo.string = ""
        let url = URL(fileURLWithPath: self.folderPath.stringValue)
        let manager = FileManager.default
        let folderpath =  "\(self.folderPath.stringValue)"
        if folderpath.count == 0 {
            errorInfo.stringValue = "No folder find"
            return
        }
        var isDir:ObjCBool = true
        manager.fileExists(atPath: folderpath, isDirectory: &isDir)
        if !isDir.boolValue{
            errorInfo.stringValue = "Please drag folder instead of file"
            return
        }
        showProcessBar(isShow: true)
        let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true) as NSArray
        let patharr: Array = folderpath.components(separatedBy: "/")
        let foldername = patharr.last!
        var enumeratorAtPath = manager.enumerator(atPath: url.path)
        var num = 0
        var process = 0
        for logpath in enumeratorAtPath! {
            if (logpath as! String).contains(".logarchive"){
                self.run(cmd: "rm -rf \(folderpath)/\(logpath)")
            }
        }
        enumeratorAtPath = manager.enumerator(atPath: url.path)
        for _ in enumeratorAtPath! {
            num = num + 1
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let newfoldername = dateFormatter.string(from: Date())
        let myfolder = "\(paths[0])/\(newfoldername)"
        try! manager.createDirectory(atPath: myfolder,withIntermediateDirectories: true, attributes: nil)
        showmessage(inputString: "File count : \(num)\n")
        var timenum = 0
        DispatchTimer(timeInterval: 1, handler: {(timer) in
            if num > 1000{
                let percent = Double(process)/Double(num)*100
                timenum = timenum + 1
                if percent == 100{
                    self.showmessage(inputString: "Total Time : \(timenum)s")
                    timer?.cancel()
                }
                if percent > 0 {
                    self.processLabel.stringValue = String.init(format: "%.0f%%", percent)
                    self.processbar.doubleValue = percent
                }
            }
        })
        enumeratorAtPath = manager.enumerator(atPath: url.path)
        let fileFlagArr:Array = [txtBtn.stringValue == "1" ? "txt" : "",logBtn.stringValue == "1" ? "log" : "",csvBtn.stringValue == "1" ? "csv" : "",plistBtn.stringValue == "1" ? "plist" : ""]
        var justfind = false
        var regexstr = ""
        for eachRegex in self.datas{
            if eachRegex["find"] as! String == "1"{
                justfind = true
                if regexstr.count > 0{
                    regexstr = "\(regexstr)|\(eachRegex["regex"] as! String)"
                }else{
                    regexstr = "\(eachRegex["regex"] as! String)"
                }
            }
        }
        if !justfind{
            for eachRegex in self.datas{
                if eachRegex["find"] as! String == "0"{
                    if regexstr.count > 0{
                        regexstr = "\(regexstr)|\(eachRegex["regex"] as! String)"
                    }else{
                        regexstr = "\(eachRegex["regex"] as! String)"
                    }
                }
            }
        }
        DispatchQueue.global().async {
            let incrementnum = 100.0/Double(num)
            self.run(cmd: "cp -R \(folderpath) \(paths[0])/\(newfoldername)")
            for logpath in enumeratorAtPath! {
                process = process + 1
                if num < 1000{
                    DispatchQueue.main.async {
                        self.processLabel.stringValue = "\(process)/\(num)"
                        self.processbar.increment(by: Double(incrementnum))
                    }
                }
                let truepath = folderpath + "/\(logpath)"
                let newpath = "\(paths[0])/\(newfoldername)/\(foldername)/\(logpath)"
                let logstylearr: Array = (logpath as! String).components(separatedBy: ".")
                if logstylearr.count > 1 && fileFlagArr.contains(logstylearr.last!){
                    let tmpData = NSData.init(contentsOfFile: truepath)
                    if (tmpData != nil) {
                        let content = String.init(data: tmpData! as Data, encoding: String.Encoding.utf8)
                        if (content != nil) {
                            var finallog = content!
                            if justfind{
                                finallog = self.findArrayInString(str: finallog, pattern: regexstr).joined(separator: "\n")
                            }else{
                                finallog = self.replaceStringInString(str: finallog, pattern: regexstr, replacewith: "")
                            }
                            if finallog.count > 0{
                                do {
                                    try finallog.write(toFile: newpath, atomically: true, encoding: .utf8)
                                } catch  {
                                    self.showmessage(inputString: "Error to write at \(newpath)")
                                }
                            }else{
                                self.run(cmd: "rm -rf \(newpath)")
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
                        self.run(cmd: "rm -rf \(newpath)")
                    }
                }
            }
            DispatchQueue.main.async {
                self.showProcessBar(isShow: false)
            }
        }
    }
    
    func findArrayInString(str:String , pattern:String ) -> [String]
    {
        do {
            var stringArray = [String]();
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let res = regex.matches(in: str, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, str.count))
            for checkingRes in res
            {
                let tmp = (str as NSString).substring(with: checkingRes.range)
                stringArray.append(tmp.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
            }
            return stringArray
        }
        catch
        {
            showmessage(inputString: "findArrayInString Regex error")
            return [String]()
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
    
    func DispatchTimer(timeInterval: Double, handler:@escaping (DispatchSourceTimer?)->())
    {
        let timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        timer.schedule(deadline: .now(), repeating: timeInterval)
        timer.setEventHandler {
            DispatchQueue.main.async {
                handler(timer)
            }
        }
        timer.resume()
    }
    
    func showProcessBar(isShow:Bool) {
        txtBtn.isHidden = isShow
        logBtn.isHidden = isShow
        csvBtn.isHidden = isShow
        plistBtn.isHidden = isShow
        exportBtn.isHidden = isShow
        processbar.isHidden = !isShow
        processLabel.isHidden = !isShow
        if isShow {
            processLabel.stringValue = "Loading..."
        }
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.datas.count
    }
}

extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return self.datas[row].object(forKey:(tableColumn?.identifier)!)
    }
    
//    func tableViewSelectionDidChange(_ notification: Notification){
//        let tableView = notification.object as! NSTableView
//        let row = tableView.selectedRow
//        print("selection row \(row)")
//    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        if (tableColumn?.identifier)!.rawValue == "find" {
            if self.datas[row].object(forKey: "find") as! String == "1"{
                self.datas[row].setObject("0", forKey: "find" as NSCopying)
            }else{
                self.datas[row].setObject("1", forKey: "find" as NSCopying)
            }
            tableView.reloadData()
        }
    }
    
//    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
//        guard let rowView = tableView.makeView(withIdentifier:NSUserInterfaceItemIdentifier(rawValue: "RowView"), owner: nil) as! NSTableRowView?
//            else {
//            let rowView = NSTableRowView()
//            rowView.identifier = NSUserInterfaceItemIdentifier(rawValue: "RowView")
//            return rowView
//        }
//        return rowView
//    }
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
