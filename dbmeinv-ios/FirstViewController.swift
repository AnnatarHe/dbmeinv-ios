//
//  FirstViewController.swift
//  dbmeinv-ios
//
//  Created by 贺乐 on 02/03/2017.
//  Copyright © 2017 贺乐. All rights reserved.
//

import UIKit
import Alamofire
//
//struct CategoryItem {
//    let id: Int
//    let name: String
//    let src: Int
//}

class FirstViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var categories: [CategoryItem?] = [CategoryItem(id: 111, name: "hello", src: 11111)]
    var selectedIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        print("fitst view")
        // Do any additional setup after loading the view, typically from a nib.
        tableView.dataSource = self
        self.requestAllCategroies()
    }
    
    func requestAllCategroies() {
        Alamofire.request("https://db.annatarhe.com/api/meinv/categories").responseJSON { response in
            if let result = response.result.value {
                if let categories = result as? [NSDictionary] {
                    for i in 0..<categories.count {
                        let id = categories[i]["id"]! as! Int
                        let name = categories[i]["name"]! as! String
                        let src = categories[i]["src"]! as! Int
                        self.categories.append(CategoryItem(id: id, name: name, src: src))
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension FirstViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categroyNameCell", for: indexPath)
        if let name = categories[indexPath.row]?.name {
            cell.textLabel?.text = name
        } else {
            cell.textLabel?.text = "nil"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
        
        self.selectedIndex = categories[indexPath.row]!.id
        performSegue(withIdentifier: "CategoryItemView", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showCategoryItem" else {
            return
        }
        let viewController = segue.destination as! CategoryItemViewController
        viewController.setSelectedIndex(index: self.selectedIndex)
    }
}
