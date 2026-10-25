import UIKit

/// 视频 Tab：只保留站点卡片，收藏统一在「收藏」Tab
final class VideoViewController: UIViewController,
                                UICollectionViewDataSource,
                                UICollectionViewDelegateFlowLayout,
                                ScrollToTopable {

    private let header = UIView()
    private let headerTitleLabel = UILabel()
    private let headerSubtitleLabel = UILabel()
    private var backgroundView: UIView?

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 16, bottom: 24, right: 16)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.alwaysBounceVertical = true
        view.dataSource = self
        view.delegate = self
        view.register(VideoSiteCard.self,
                      forCellWithReuseIdentifier: VideoSiteCard.reuseID)
        return view
    }()

    private var sites: [VideoSite] = []
    private let emptyLabel = UILabel()
    private var videoSitesObserver: NSObjectProtocol?

    deinit {
        if let observer = videoSitesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        CrashLogger.log("video tab loaded")
        view.backgroundColor = Theme.bgTop
        let background = Theme.makeBackgroundView(view.bounds)
        background.frame = view.bounds
        background.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(background, at: 0)
        backgroundView = background

        sites = VideoSiteStore.shared.sites
        setupHeader()
        setupGrid()

        videoSitesObserver = NotificationCenter.default.addObserver(forName: .videoSitesChanged,
                                                                   object: nil,
                                                                   queue: .main) { [weak self] _ in
            self?.reloadSites()
        }
        reloadSites()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        CrashLogger.log("video tab will appear")
        navigationController?.setNavigationBarHidden(true, animated: animated)
        reloadSites()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundView?.frame = view.bounds
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    func scrollToTop() {
        let top = -collectionView.adjustedContentInset.top
        collectionView.setContentOffset(CGPoint(x: 0, y: top), animated: true)
    }

    // MARK: - 头部

    private func setupHeader() {
        header.backgroundColor = .clear
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        headerTitleLabel.text = "视频"
        headerTitleLabel.font = Theme.rounded(20, .bold)
        headerTitleLabel.textColor = Theme.text
        headerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(headerTitleLabel)

        headerSubtitleLabel.text = "选择站点，在 App 内观看"
        headerSubtitleLabel.font = Theme.font(12, .regular)
        headerSubtitleLabel.textColor = Theme.textDim
        headerSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(headerSubtitleLabel)

        let headerLine = UIView()
        headerLine.backgroundColor = Theme.cardBorder
        headerLine.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(headerLine)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 72),

            headerTitleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            headerTitleLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: 6),
            headerTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor, constant: -16),

            headerSubtitleLabel.leadingAnchor.constraint(equalTo: headerTitleLabel.leadingAnchor),
            headerSubtitleLabel.topAnchor.constraint(equalTo: headerTitleLabel.bottomAnchor, constant: 0),
            headerSubtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor, constant: -16),

            headerLine.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            headerLine.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            headerLine.bottomAnchor.constraint(equalTo: header.bottomAnchor),
            headerLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    private func setupGrid() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        emptyLabel.text = "还没有视频站点\n到 设置 → 视频站点 添加"
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = Theme.textDim
        emptyLabel.font = Theme.font(13, .regular)
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: header.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func reloadSites() {
        sites = VideoSiteStore.shared.sites
        collectionView.reloadData()
        emptyLabel.isHidden = !sites.isEmpty
    }

    private func openVideo(url: URL, title: String) {
        guard navigationController?.topViewController === self else { return }
        VideoOpener.open(url: url,
                         title: title,
                         from: self,
                         navigation: navigationController)
    }

    // MARK: - 卡片

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sites.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoSiteCard.reuseID,
                                                      for: indexPath) as! VideoSiteCard
        cell.configure(site: sites[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 10
        let available = collectionView.bounds.width - 32 - spacing
        let width = max(120, available / 2)
        return CGSize(width: width, height: 108)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard indexPath.item < sites.count,
              let url = URL(string: sites[indexPath.item].url) else { return }
        openVideo(url: url, title: sites[indexPath.item].name)
    }

    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPath.item < sites.count else { return nil }
        let site = sites[indexPath.item]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let copy = UIAction(title: "复制链接",
                                image: UIImage(systemName: "link")) { _ in
                UIPasteboard.general.string = site.url
                Haptics.success()
            }
            return UIMenu(title: site.name, children: [copy])
        }
    }
}

/// 视频站点卡片
final class VideoSiteCard: UICollectionViewCell {

    static let reuseID = "VideoSiteCard"

    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let hostLabel = UILabel()
    private let playIcon = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = Theme.card
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = Theme.cardBorder.cgColor
        contentView.layer.masksToBounds = true

        emojiLabel.font = .systemFont(ofSize: 28)
        emojiLabel.textColor = Theme.text
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emojiLabel)

        playIcon.image = UIImage(systemName: "play.circle.fill")
        playIcon.tintColor = Theme.accent
        playIcon.alpha = 0.9
        playIcon.contentMode = .scaleAspectFit
        playIcon.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(playIcon)

        titleLabel.font = Theme.rounded(15, .semibold)
        titleLabel.textColor = Theme.text
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        hostLabel.font = Theme.font(12, .regular)
        hostLabel.textColor = Theme.textDim
        hostLabel.lineBreakMode = .byTruncatingTail
        hostLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hostLabel)

        NSLayoutConstraint.activate([
            emojiLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            emojiLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            playIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            playIcon.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            playIcon.widthAnchor.constraint(equalToConstant: 20),
            playIcon.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            titleLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 11),

            hostLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            hostLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            hostLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            hostLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.contentView.alpha = self.isHighlighted ? 0.72 : 1
            }
        }
    }

    func configure(site: VideoSite) {
        emojiLabel.text = site.emoji
        titleLabel.text = site.name
        hostLabel.text = site.note
    }
}
