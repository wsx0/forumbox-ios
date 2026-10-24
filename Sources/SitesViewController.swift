import UIKit

final class SitesViewController: UITableViewController {

    private let bgColor = UIColor(red: 11/255, green: 18/255, blue: 32/255, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "论坛盒子"
        view.backgroundColor = bgColor
        tableView.backgroundColor = bgColor
        tableView.separatorStyle = .none
        tableView.rowHeight = 80
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        tableView.register(SiteCell.self, forCellReuseIdentifier: "SiteCell")
        navigationItem.backButtonDisplayMode = .minimal
        navigationController?.navigationBar.prefersLargeTitles = false
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
        let vc = WebViewController(site: site)
        navigationController?.pushViewController(vc, animated: true)
    }
}

final class SiteCell: UITableViewCell {

    private let container = UIView()
    private let nameLabel = UILabel()
    private let noteLabel = UILabel()
    private let urlLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        container.backgroundColor = UIColor(red: 18/255, green: 30/255, blue: 53/255, alpha: 1)
        container.layer.cornerRadius = 14
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(red: 30/255, green: 47/255, blue: 76/255, alpha: 1).cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        noteLabel.font = .systemFont(ofSize: 11, weight: .regular)
        noteLabel.textColor = UIColor(red: 125/255, green: 211/255, blue: 252/255, alpha: 1)
        noteLabel.translatesAutoresizingMaskIntoConstraints = false
        noteLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        noteLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        urlLabel.font = .systemFont(ofSize: 11, weight: .regular)
        urlLabel.textColor = UIColor(red: 100/255, green: 116/255, blue: 139/255, alpha: 1)
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

            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),

            noteLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 10),
            noteLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            noteLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -14),

            urlLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            urlLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            urlLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 7)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with site: Site) {
        nameLabel.text = site.name
        noteLabel.text = site.note
        var display = site.url
        if display.hasPrefix("https://") { display = String(display.dropFirst(8)) }
        if display.hasPrefix("http://") { display = String(display.dropFirst(7)) }
        urlLabel.text = display
    }
}
