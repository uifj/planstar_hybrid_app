import UIKit

/// 书架三列封面单元格。
///
/// 与原项目一致：3:4 封面 + 单行书名 + 单行作者；
/// 封面使用渐变底色 + 书名首字（无封面图时的占位方案，对应 Android `bg_book_cover`）。
@MainActor
final class BookGridCell: UICollectionViewCell {

    private let coverView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let coverCharLabel = UILabel()
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = coverView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        authorLabel.text = nil
        coverCharLabel.text = nil
    }

    func configure(with book: BookItem?) {
        let item = book ?? BookItem()
        titleLabel.text = item.bookName ?? ""
        authorLabel.text = item.author ?? ""
        coverCharLabel.text = item.bookName.map { String($0.prefix(1)) } ?? ""
    }

    private func setupViews() {
        contentView.backgroundColor = .clear

        coverView.layer.cornerRadius = 8
        coverView.layer.masksToBounds = true
        coverView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(coverView)

        gradientLayer.colors = [AppTheme.coverStart.cgColor, AppTheme.coverEnd.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        coverView.layer.addSublayer(gradientLayer)

        coverCharLabel.font = AppTheme.font(30, weight: .bold)
        coverCharLabel.textColor = .white
        coverCharLabel.textAlignment = .center
        coverCharLabel.translatesAutoresizingMaskIntoConstraints = false
        coverView.addSubview(coverCharLabel)

        titleLabel.font = AppTheme.font(13)
        titleLabel.textColor = AppTheme.textPrimary
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        authorLabel.font = AppTheme.font(11)
        authorLabel.textColor = AppTheme.textTertiary
        authorLabel.numberOfLines = 1
        authorLabel.lineBreakMode = .byTruncatingTail
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(authorLabel)

        NSLayoutConstraint.activate([
            coverView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coverView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coverView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            coverView.heightAnchor.constraint(equalTo: coverView.widthAnchor, multiplier: 4.0 / 3.0),

            coverCharLabel.topAnchor.constraint(equalTo: coverView.topAnchor),
            coverCharLabel.leadingAnchor.constraint(equalTo: coverView.leadingAnchor),
            coverCharLabel.trailingAnchor.constraint(equalTo: coverView.trailingAnchor),
            coverCharLabel.bottomAnchor.constraint(equalTo: coverView.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: coverView.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            authorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            authorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
}
