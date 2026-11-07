import UIKit

/// 书架页（原生）。
///
/// 分层：presentation 只依赖 domain 用例（`GetBookshelfUseCase`），
/// 网络 / 本地回退逻辑封装在 data 层的 `BookRepositoryImpl` 中。
@MainActor
final class BookshelfViewController: UIViewController {

    private static let cellIdentifier = "BookGridCell"
    private static let readerChapterCount = 30

    private let getBookshelf = ServiceLocator.shared.getBookshelfUseCase

    private var items: [BookShelfItem] = []
    private var refreshTask: Task<Void, Never>?

    private let headerBar = UIView()
    private let titleLabel = UILabel()
    private let sourceLabel = UILabel()
    private let flowLayout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)

    deinit {
        refreshTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.background
        setupHeader()
        setupCollectionView()
        load()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let itemWidth = floor((collectionView.bounds.width - 24 - 16) / 3)
        let size = CGSize(width: itemWidth, height: itemWidth * 4 / 3 + 38)
        if flowLayout.itemSize != size {
            flowLayout.itemSize = size
            flowLayout.invalidateLayout()
        }
    }

    // MARK: - UI

    private func setupHeader() {
        headerBar.backgroundColor = .white
        headerBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerBar)

        titleLabel.text = "我的书架"
        titleLabel.font = AppTheme.font(18, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(titleLabel)

        sourceLabel.font = AppTheme.font(11)
        sourceLabel.textColor = AppTheme.primary
        sourceLabel.textAlignment = .right
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(sourceLabel)

        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 52),

            sourceLabel.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor, constant: -16),
            sourceLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            sourceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),

            headerBar.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor),
        ])
    }

    private func setupCollectionView() {
        flowLayout.minimumInteritemSpacing = 8
        flowLayout.minimumLineSpacing = 12
        flowLayout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(BookGridCell.self, forCellWithReuseIdentifier: Self.cellIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - 数据

    /// 首屏直接渲染本地缓存：进书架即有内容，不等待网络。
    /// 后台刷新只有真正拿到网络数据才更新，失败保持缓存不闪动。
    private func load() {
        apply(items: getBookshelf.cached(), fromNetwork: false)

        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            let result = await self.getBookshelf()
            guard !Task.isCancelled else { return }
            guard result.fromNetwork, !result.items.isEmpty else { return }
            self.apply(items: result.items, fromNetwork: true)
        }
    }

    private func apply(items: [BookShelfItem], fromNetwork: Bool) {
        self.items = items
        collectionView.reloadData()
        sourceLabel.text = fromNetwork ? "网络书单" : "本地书单"
    }
}

// MARK: - UICollectionViewDataSource / Delegate

extension BookshelfViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: Self.cellIdentifier,
            for: indexPath
        )
        (cell as? BookGridCell)?.configure(with: items[indexPath.item].bookItem)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let book = items[indexPath.item].bookItem ?? BookItem()
        let reader = ReaderViewController(
            bookId: book.bookId,
            title: book.bookName ?? "",
            author: book.author ?? "",
            chapterCount: Self.readerChapterCount
        )
        reader.hidesBottomBarWhenPushed = true
        if let navigationController {
            navigationController.pushViewController(reader, animated: true)
        } else {
            reader.modalPresentationStyle = .fullScreen
            present(reader, animated: true)
        }
    }
}
