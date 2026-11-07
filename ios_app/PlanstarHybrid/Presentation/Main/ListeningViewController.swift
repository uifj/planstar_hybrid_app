import UIKit

/// 听书页（原生）：模拟有声书列表与播放状态（对应 Android `ListeningFragment`）。
@MainActor
final class ListeningViewController: UIViewController {

    private static let cellIdentifier = "AudioCell"
    private static let rowHeight: CGFloat = 92

    private let headerBar = UIView()
    private let titleLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var playingIndexes: Set<Int> = []

    private let items: [AudioBookItem] = [
        AudioBookItem(bookName: "元尊", speaker: "主播：有声土豆", duration: "时长 08:32"),
        AudioBookItem(bookName: "庆余年", speaker: "主播：范闲工作室", duration: "时长 12:47"),
        AudioBookItem(bookName: "诡秘之主", speaker: "主播：愚者电台", duration: "时长 15:20"),
        AudioBookItem(bookName: "凡人修仙传", speaker: "主播：修仙FM", duration: "时长 09:05"),
        AudioBookItem(bookName: "大奉打更人", speaker: "主播：打更人广播", duration: "时长 11:38"),
        AudioBookItem(bookName: "赘婿", speaker: "主播：江宁说书人", duration: "时长 14:02"),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.background
        setupHeader()
        setupTableView()
    }

    private func setupHeader() {
        headerBar.backgroundColor = .white
        headerBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerBar)

        titleLabel.text = "听书"
        titleLabel.font = AppTheme.font(18, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 52),

            headerBar.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor),
        ])
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = Self.rowHeight
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AudioCell.self, forCellReuseIdentifier: Self.cellIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: - UITableViewDataSource / Delegate

extension ListeningViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.cellIdentifier,
            for: indexPath
        )
        guard let audioCell = cell as? AudioCell else { return cell }
        audioCell.configure(
            with: items[indexPath.row],
            progress: Float((indexPath.row * 13) % 90) / 100,
            isPlaying: playingIndexes.contains(indexPath.row)
        )
        audioCell.onTogglePlay = { [weak self] in
            guard let self else { return }
            if self.playingIndexes.contains(indexPath.row) {
                self.playingIndexes.remove(indexPath.row)
            } else {
                self.playingIndexes.insert(indexPath.row)
            }
            // 只刷新播放按钮，避免整行（封面、文本、进度条）重新绑定
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
        return audioCell
    }
}
