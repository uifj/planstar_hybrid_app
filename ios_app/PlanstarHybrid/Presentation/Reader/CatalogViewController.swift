import UIKit

/// 目录弹窗（对应 Android `dialog_catalog.xml` + BottomSheetDialog）：
/// 底部半屏 / 全屏目录，当前章节高亮，点击切换章节。
@MainActor
final class CatalogViewController: UIViewController {

    private static let cellIdentifier = "CatalogCell"

    private let chapters: [Chapter]
    private let currentIndex: Int
    private let onSelect: (Int) -> Void

    private let headerLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)

    init(chapters: [Chapter], currentIndex: Int, onSelect: @escaping (Int) -> Void) {
        self.chapters = chapters
        self.currentIndex = currentIndex
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.scrollToRow(
            at: IndexPath(row: currentIndex, section: 0),
            at: .middle,
            animated: false
        )
    }

    private func setupViews() {
        headerLabel.text = "目录"
        headerLabel.font = AppTheme.font(16, weight: .bold)
        headerLabel.textColor = AppTheme.textPrimary
        headerLabel.textAlignment = .center
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerLabel)

        tableView.backgroundColor = .white
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 56, bottom: 0, right: 16)
        tableView.rowHeight = 52
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerLabel.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: - UITableViewDataSource / Delegate

extension CatalogViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        chapters.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath)
        cell.textLabel?.text = chapters[indexPath.row].chapterName
        cell.textLabel?.font = AppTheme.font(15)
        cell.textLabel?.textColor = indexPath.row == currentIndex
            ? AppTheme.primary
            : AppTheme.textPrimary
        cell.backgroundColor = .white
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss(animated: true) { [weak self] in
            self?.onSelect(indexPath.row)
        }
    }
}
