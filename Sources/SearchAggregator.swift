import Foundation

/// 聚合搜索：把关键词分发给各站的搜索页，抓取结果链接
final class SearchAggregator {

    struct SiteResult {
        let site: Site
        var status: String
        var items: [(title: String, url: String)]
    }

    private let engine = SiteFetchAggregator()

    func cancel() {
        engine.cancel()
    }

    func search(query: String,
                sites: [Site],
                update: @escaping (SiteResult) -> Void,
                finished: @escaping () -> Void) {
        engine.start(sites: sites,
                     needsAutoSearch: true,
                     urlForSite: { site in
                        guard let searchURL = site.searchURL, !searchURL.isEmpty else { return nil }
                        let encoded = query.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
                        return searchURL + "#fbq=" + encoded
                     },
                     update: { result in
                        update(SiteResult(site: result.site,
                                          status: result.status,
                                          items: result.items.map { ($0.title, $0.url) }))
                     },
                     finished: finished)
    }
}
