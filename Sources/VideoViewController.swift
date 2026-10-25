import UIKit
import SafariServices

/// 视频 Tab：固定头部 + 两列站点卡片
final class VideoViewController: UIViewController,
                                UICollectionViewDataSource,
                                UICollectionViewDelegateFlowLayout,
                                UITextFieldDelegate,
                                ScrollToTopable {

    private let header = UIView()
    private let headerTitleLabel = UILabel()
    private let headerSubtitleLabel = UILabel()
    private let inputContainer = UIView()
    private let inputField = UITextField()
    private let openButton = UIButton(type: .system)

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 16, bottom: 24, right: 16)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.alwaysBounceVertical = true
        view.keyboardDismissMode = .onDrag
        view.dataSource = self
        view.delegate = self
        view.register(VideoSiteCard.self,
                      forCellWithReuseIdentifier: VideoSiteCard.reuseID)
        return view
    }()

    private let sites = VideoSites.all

    override func viewDidLoad() {
        super.viewDidLoad()
        CrashLogger.log("video tab loaded")
        view.backgroundColor = Theme.bgTop
        setupHeader()
        setupGrid()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        CrashLogger.log("video tab will appear")
        navigationController?.setNavigationBarHidden(true, animated: animated)
        collectionView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.backgroundView?.frame = collectionView.bounds
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
        header.backgroundColor = Theme.bgTop
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        headerTitleLabel.text = "视频"
        headerTitleLabel.font = Theme.rounded(20, .bold)
        headerTitleLabel.textColor = Theme.text
        headerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(headerTitleLabel)

        headerSubtitleLabel.text = "输入链接，或点卡片在 App 内观看"
        headerSubtitleLabel.font = Theme.font(12, .regular)
        headerSubtitleLabel.textColor = Theme.textDim
        headerSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(headerSubtitleLabel)

        inputContainer.backgroundColor = Theme.card
        inputContainer.layer.cornerRadius = 12
        inputContainer.layer.borderWidth = 1
        inputContainer.layer.borderColor = Theme.cardBorder.cgColor
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(inputContainer)

        inputField.placeholder = "输入视频链接或网站"
        inputField.font = Theme.font(14, .regular)
        inputField.textColor = Theme.text
        inputField.tintColor = Theme.accent
        inputField.keyboardType = .URL
        inputField.returnKeyType = .go
        inputField.autocapitalizationType = .none
        inputField.autocorrectionType = .no
        inputField.clearButtonMode = .whileEditing
        inputField.delegate = self
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(inputField)

        openButton.setTitle("打开", for: .normal)
        openButton.setTitleColor(Theme.onAccent, for: .normal)
        openButton.titleLabel?.font = Theme.rounded(13, .semibold)
        openButton.backgroundColor = Theme.accent
        openButton.layer.cornerRadius = 17
        openButton.addTarget(self, action: #selector(openTypedURL), for: .touchUpInside)
        openButton.addTarget(self, action: #selector(openButtonDown), for: .touchDown)
        openButton.addTarget(self, action: #selector(openButtonUp),
                             for: [.touchUpInside, .touchUpOutside, .touchCancel])
        openButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(openButton)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 108),

            headerTitleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            headerTitleLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: 6),
            headerTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor, constant: -16),

            headerSubtitleLabel.leadingAnchor.constraint(equalTo: headerTitleLabel.leadingAnchor),
            headerSubtitleLabel.topAnchor.constraint(equalTo: headerTitleLabel.bottomAnchor, constant: 0),
            headerSubtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor, constant: -16),

            inputContainer.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            inputContainer.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            inputContainer.topAnchor.constraint(equalTo: header.topAnchor, constant: 56),
            inputContainer.heightAnchor.constraint(equalToConstant: 44),

            inputField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
            inputField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            inputField.trailingAnchor.constraint(equalTo: openButton.leadingAnchor, constant: -8),

            openButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -5),
            openButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            openButton.heightAnchor.constraint(equalToConstant: 34),
            openButton.widthAnchor.constraint(equalToConstant: 64)
        ])
    }

    private func setupGrid() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        collectionView.backgroundView = Theme.makeBackgroundView(collectionView.bounds)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: header.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - 链接

    @objc private func openTypedURL() {
        var text = (inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            presentNotice("先输入一个视频链接")
            return
        }
        let lower = text.lowercased()
        if !lower.hasPrefix("http://") && !lower.hasPrefix("https://") {
            text = "https://" + text
        }
        guard let url = URL(string: text),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            presentNotice("链接格式不正确，需要 http/https 地址")
            return
        }
        inputField.resignFirstResponder()
        inputField.text = ""
        openVideo(url: url)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        openTypedURL()
        return true
    }

    @objc private func openButtonDown() {
        openButton.alpha = 0.78
    }

    @objc private func openButtonUp() {
        UIView.animate(withDuration: 0.15) {
            self.openButton.alpha = 1
        }
    }

    private func openVideo(url: URL, title: String? = nil) {
        guard navigationController?.topViewController === self else { return }
        Haptics.tap()
        let host = url.host ?? "视频"
        let name = title ?? host

        if AppSettings.shared.videoUseSystemPlayer {
            CrashLogger.log("open video system \(url.absoluteString)")
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = Theme.accent
            safari.modalPresentationStyle = .fullScreen
            CrashLogger.log("presenting safari \(url.absoluteString)")
            present(safari, animated: true) {
                CrashLogger.log("safari presented \(url.absoluteString)")
            }
            return
        }

        CrashLogger.log("open video builtin \(url.absoluteString)")
        let controller = WebViewController(title: name, urlString: url.absoluteString, videoMode: true)
        navigationController?.pushViewController(controller, animated: true)
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
