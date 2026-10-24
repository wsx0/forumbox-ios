import UIKit

final class SitesViewController: UITableViewController {

    private lazy var searchButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = "搜索 7 个论坛"
        config.image = UIImage(systemName: "sparkles")
        config.imagePadding = 8
        config.baseForegroundColor = Theme.textDim
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = Theme.rounded(14.5, .semibold)
            return out
        }
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        button.backgroundColor = Theme.card
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = Theme.cardBorder.cgColor
        button.addTarget(self, action: #selector(openSearch), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "论坛盒子"
        view.backgroundColor = Theme.bgTop
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 82
        tableView.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 24, right: 0)
        tableView.register(SiteCell.self, forCellReuseIdentifier: "SiteCell")
        navigationItem.backButtonDisplayMode = .minimal
        navigationController?.navigationBar.prefersLargeTitles = false
        tableView.backgroundView = Theme.makeBackgroundView(tableView.bounds)
        setupSearchHeader()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let background = tableView.backgroundView {
            background.frame = tableView.bounds
        }
    }

    private func setupSearchHeader() {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 66))
        header.backgroundColor = .clear
        searchButton.frame = CGRect(x: 16, y: 10, width: header.bounds.width - 32, height: 46)
        searchButton.autoresizingMask = [.flexibleWidth]
        header.addSubview(searchButton)
        tableView.tableHeaderView = header
    }

    @objc private func openSearch() {
        navigationController?.pushViewController(SearchViewController(style: .plain), animated: true)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Sites.all.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SiteCell", for: indexPath) as! SiteCell
        cell.configure(with: Sites.all[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let site = Sites.all[indexPath.row]
        navigationController?.pushViewController(WebViewController(site: site), animated: true)
    }
}

final class SiteCell: UITableViewCell {

    private let container = UIView()
    private let emojiBackground = UIView()
    private let emojiLabel = UILabel()
    private let nameLabel = UILabel()
    private let noteLabel = UILabel()
    private let urlLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        container.backgroundColor = Theme.card
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 1
        container.layer.borderColor = Theme.cardBorder.cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        emojiBackground.backgroundColor = Theme.emojiBg
        emojiBackground.layer.cornerRadius = 11
        emojiBackground.layer.borderWidth = 1
        emojiBackground.layer.borderColor = Theme.cardBorder.cgColor
        emojiBackground.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(emojiBackground)

        emojiLabel.font = .systemFont(ofSize: 21)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiBackground.addSubview(emojiLabel)

        nameLabel.font = Theme.rounded(16.5)
        nameLabel.textColor = Theme.text
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        noteLabel.font = .systemFont(ofSize: 10.5, weight: .medium)
        noteLabel.textColor = Theme.accent
        noteLabel.translatesAutoresizingMaskIntoConstraints = false
        noteLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        urlLabel.font = .systemFont(ofSize: 10.5, weight: .regular)
        urlLabel.textColor = Theme.textFaint
        urlLabel.translatesAutoresizingMaskIntoConstraints = false
        urlLabel.lineBreakMode = .byTruncatingMiddle

        container.addSubview(nameLabel)
        container.addSubview(noteLabel)
        container.addSubview(urlLabel)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),

            emojiBackground.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 13),
            emojiBackground.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            emojiBackground.widthAnchor.constraint(equalToConstant: 40),
            emojiBackground.heightAnchor.constraint(equalToConstant: 40),

            emojiLabel.centerXAnchor.constraint(equalTo: emojiBackground.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiBackground.centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: emojiBackground.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 13),

            noteLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            noteLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            noteLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -14),

            urlLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            urlLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            urlLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with site: Site) {
        emojiLabel.text = site.emoji
        nameLabel.text = site.name
        noteLabel.text = site.note
        var display = site.url
        if display.hasPrefix("https://") { display = String(display.dropFirst(8)) }
        if display.hasPrefix("http://") { display = String(display.dropFirst(7)) }
        urlLabel.text = display
    }
}
