//
//  RequestSeatViewController.swift
//  RCE
//
//  Created by 叶孤城 on 2021/5/7.
//

import UIKit
import SVProgressHUD


class RequestSeatViewController: UIViewController {
    private lazy var tableView: UITableView = {
        let instance = UITableView(frame: .zero, style: .plain)
        instance.backgroundColor = .clear
        instance.separatorStyle = .none
        instance.register(cellType: RequestSeatTableViewCell.self)
        instance.dataSource = self
        return instance
    }()
    private lazy var emptyView = RCSRUsersEmptyView()
    private let acceptUserCallback:((String) -> Void)
    
    private let requesterIds: [String]
    private var requesterInfos: [RCSceneRoomUser] = [RCSceneRoomUser]()
    
    init(requesterIds: [String], callback: @escaping ((String) -> Void)) {
        self.acceptUserCallback = callback
        self.requesterIds = requesterIds
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40.resize)
            make.width.height.equalTo(160.resize)
        }
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        emptyView.isHidden = requesterIds.count > 0
        fetchAllUserInfo()
    }
    
    private func buildLayout() {
        view.backgroundColor = RCSCAsset.Colors.hex03062F.color.withAlphaComponent(0.5)
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.left.bottom.right.equalToSuperview()
            $0.top.equalToSuperview().offset(220.resize)
        }
    }
    
    private func fetchAllUserInfo() {
        voiceRoomService.usersInfo(id: self.requesterIds) { result in
            switch result.map(RCSceneWrapper<[RCSceneRoomUser]>.self) {
            case let .success(wrapper):
                guard let list = wrapper.data else {return}
                self.requesterInfos = list
                self.tableView.reloadData()
            case let .failure(error):
                debugPrint(error.localizedDescription)
            }
        }
    }
}

extension RequestSeatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requesterInfos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: RequestSeatTableViewCell.self)
        cell.updateCell(user: requesterInfos[indexPath.row])
        cell.acceptCallback = {
           [weak self] userId in
            self?.acceptUserCallback(userId)
        }
        return cell
    }
}
