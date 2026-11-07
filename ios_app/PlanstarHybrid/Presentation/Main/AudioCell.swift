import UIKit

/// 听书列表单元格（对应 Android `item_audio.xml` + `AudioAdapter`）：
/// 封面 + 书名 + 主播/时长 + 播放进度 + 播放按钮。
@MainActor
final class AudioCell: UITableViewCell {

    private let cardView = UIView()
    private let coverView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let coverCharLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let playButton = UIButton(type: .system)

    var onTogglePlay: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
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
        subtitleLabel.text = nil
        coverCharLabel.text = nil
        onTogglePlay = nil
    }

    func configure(with book: AudioBookItem, progress: Float, isPlaying: Bool) {
        titleLabel.text = book.bookName ?? ""
        subtitleLabel.text = "\(book.speaker ?? "") · \(book.duration ?? "")"
        coverCharLabel.text = book.bookName.map { String($0.prefix(1)) } ?? ""
        progressView.progress = progress
        let symbol = isPlaying ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: symbol), for: .normal)
    }

    private func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        cardView.backgroundColor = .white
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        coverView.layer.cornerRadius = 8
        coverView.layer.masksToBounds = true
        coverView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(coverView)

        gradientLayer.colors = [AppTheme.coverStart.cgColor, AppTheme.coverEnd.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        coverView.layer.addSublayer(gradientLayer)

        coverCharLabel.font = AppTheme.font(24, weight: .bold)
        coverCharLabel.textColor = .white
        coverCharLabel.textAlignment = .center
        coverCharLabel.translatesAutoresizingMaskIntoConstraints = false
        coverView.addSubview(coverCharLabel)

        titleLabel.font = AppTheme.font(15, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        subtitleLabel.font = AppTheme.font(12)
        subtitleLabel.textColor = AppTheme.textGrey
        subtitleLabel.numberOfLines = 1
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtitleLabel)

        progressView.progressTintColor = AppTheme.primary
        progressView.trackTintColor = AppTheme.divider
        progressView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(progressView)

        playButton.tintColor = AppTheme.primary
        playButton.backgroundColor = AppTheme.primary.withAlphaComponent(0.08)
        playButton.layer.cornerRadius = 20
        playButton.addTarget(self, action: #selector(handleTogglePlay), for: .touchUpInside)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(playButton)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            coverView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            coverView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            coverView.widthAnchor.constraint(equalToConstant: 64),
            coverView.heightAnchor.constraint(equalToConstant: 64),

            coverCharLabel.topAnchor.constraint(equalTo: coverView.topAnchor),
            coverCharLabel.leadingAnchor.constraint(equalTo: coverView.leadingAnchor),
            coverCharLabel.trailingAnchor.constraint(equalTo: coverView.trailingAnchor),
            coverCharLabel.bottomAnchor.constraint(equalTo: coverView.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: coverView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: -8),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            progressView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 6),
            progressView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            playButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            playButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 40),
            playButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    @objc private func handleTogglePlay() {
        onTogglePlay?()
    }
}
