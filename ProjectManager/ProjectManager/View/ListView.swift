//
//  ListView.swift
//  ProjectManager
//
//  Created by leewonseok on 2023/01/11.
//

import UIKit
import RxCocoa
import RxSwift

protocol ListViewDelegate: AnyObject, CellDelegate, WorkFormDelegate {
    func deleteWork(work: Work)
    func presentModal(_ viewController: UIViewController, animated: Bool)
}

final class ListView: UIView {
    let viewModel: ListViewModel
    let disposeBag: DisposeBag = .init()
    weak var delegate: ListViewDelegate?
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 10
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ListCell.self, forCellReuseIdentifier: ListCell.identifier)
        tableView.backgroundColor = .systemGray5
        return tableView
    }()
    
    private let lineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray2
        return view
    }()
    
    private let categoryStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: .zero, right: 10)
        stackView.spacing = 5
        return stackView
    }()
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .title2)
        return label
    }()
    
    private let categoryCountLabel: CircleLabel = {
        let label = CircleLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .black
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    private let blankView: UIView = {
        let view = UIView()
        return view
    }()
    
    init(viewModel: ListViewModel) {
        self.viewModel = viewModel
        super.init(frame: CGRect())
        configureTableView()
        configureBind()
        configureLayout()
        configureData()
        backgroundColor = .systemGray5
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func didChangeWorkList(works: [Work]) {
        viewModel.workList.accept(works)
    }
    
    private func configureData() {
        categoryLabel.text = "\(viewModel.category)"
    }
    
    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func configureBind() {
        viewModel.categoryCount
            .subscribe { [weak self] count in
                self?.categoryCountLabel.text = count.element?.description
            }.disposed(by: disposeBag)
        
        viewModel.workList
            .subscribe { [weak self] _ in
                self?.tableView.reloadData()
            }.disposed(by: disposeBag)
    }
    
    private func configureLayout() {
        categoryStackView.addArrangedSubview(categoryLabel)
        categoryStackView.addArrangedSubview(categoryCountLabel)
        categoryStackView.addArrangedSubview(blankView)
        stackView.addArrangedSubview(categoryStackView)
        stackView.addArrangedSubview(lineView)
        stackView.addArrangedSubview(tableView)
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            
            lineView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}

extension ListView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.workList.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ListCell.identifier, for: indexPath)
                as? ListCell else { return ListCell() }
        
        cell.delegate = delegate
        
        cell.configureData(viewModel: ListCellViewModel(work: viewModel.workList.value[indexPath.row]))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        delegate?.deleteWork(work: viewModel.workList.value[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let workFormViewController = WorkFormViewController()
        let navigationViewController = UINavigationController(rootViewController: workFormViewController)
        
        workFormViewController.viewModel =
        WorkFormViewModel(work: viewModel.workList.value[indexPath.row])
        
        workFormViewController.delegate = delegate
        navigationViewController.modalPresentationStyle = UIModalPresentationStyle.formSheet
        
        delegate?.presentModal(navigationViewController, animated: true)
    }
}
