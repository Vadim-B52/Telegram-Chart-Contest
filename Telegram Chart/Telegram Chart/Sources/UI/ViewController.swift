//
//  ViewController.swift
//  Telegram Chart
//
//  Created by Vadim on 10/03/2019.
//  Copyright © 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    private let model = ChartListScreen()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        reloadButtonsAnimated(false)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

    @objc
    private func handleNightModeButtonTap() {
        model.switchMode()
        reloadButtonsAnimated(true)
        updateSkin()
    }
    
    private func reloadButtonsAnimated(_ animated: Bool) {
        let title = model.isNightModeEnabled ?
            NSLocalizedString("Switch to Day Mode", comment: "") :
            NSLocalizedString("Switch To Night Mode", comment: "")
        
        let button = UIBarButtonItem(title: title,
                                     style: .plain,
                                     target: self,
                                     action: #selector(handleNightModeButtonTap))
        
        navigationItem.setRightBarButtonItems([button], animated: animated)
    }
    
    private func updateSkin() {
        // TODO: implement
    }
}

