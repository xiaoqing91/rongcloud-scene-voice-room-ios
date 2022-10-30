//
//  ViewController.swift
//  RCSceneExample
//
//  Created by shaoshuai on 2022/3/19.
//

import SVProgressHUD
import RCSceneVoiceRoom

class HomeViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private lazy var refreshControl: UIRefreshControl = {
        let instance = UIRefreshControl()
        instance.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return instance
    }()
    
    private var rooms = [RCSceneRoom]()
    
    private var currentPage: Int = 1
    
    private lazy var service = RCVideoRoomService()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        tableView.refreshControl = refreshControl
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false;
        connection()
    }

    @objc func refresh() {
        service.roomList { result in
            switch result {
            case let .success(rooms):
                self.rooms = rooms
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            case let .failure(error):
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
    
    @IBAction func create() {
        let actionSheet = UIAlertController(title: "创建房间", message: nil, preferredStyle: .alert)
        actionSheet.addTextField(configurationHandler: { textField in
            textField.placeholder = "输入房间名字"
        })
        let createAction = UIAlertAction(title: "创建房间", style: .default, handler: { action in
            let roomNameField = actionSheet.textFields?[0];
            self.createRoom(name: roomNameField?.text)
        })
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        actionSheet.addAction(createAction)
        actionSheet.addAction(cancelAction)
        self.present(actionSheet, animated: true)
    
    }
    
    func createRoom(name: String?) {
        guard let name = name else { return }
        service.createRoom(name: name) { result in
            switch result {
            case let .success(roomInfo):
                self.navigationController?.navigationBar.isHidden = true;
                let controller = RCVoiceRoomController(room: roomInfo, creation: true)
                controller.view.backgroundColor = .black
                self.navigationController?.pushViewController(controller, animated: true)
            case let .failure(error):
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
            
        }
    }
}

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        return (cell as! RCVideoRoomCell).updateUI(rooms[indexPath.item])
    }
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.navigationController?.navigationBar.isHidden = true;
        let controller = RCVoiceRoomController(room: rooms[indexPath.row])
        controller.view.backgroundColor = .black
        navigationController?.pushViewController(controller, animated: true)
    }
}
