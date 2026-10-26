import Foundation

/// 广告/弹窗域名识别
enum AdBlock {

    private static let hosts: Set<String> = [
        "doubleclick.net", "googlesyndication.com", "googleadservices.com",
        "google-analytics.com", "googletagmanager.com", "googletagservices.com",
        "adnxs.com", "rubiconproject.com", "pubmatic.com", "openx.net",
        "casalemedia.com", "smartadserver.com", "adform.net", "adsrvr.org",
        "bidswitch.net", "contextweb.com", "sharethrough.com", "teads.tv",
        "spotxchange.com", "spotx.tv", "criteo.com", "criteo.net",
        "taboola.com", "outbrain.com", "mgid.com", "revcontent.com",
        "adcash.com", "propellerads.com", "propellerclick.com", "adsterra.com",
        "hilltopads.net", "hilltopads.com", "clickadu.com", "popads.net",
        "popcash.net", "popmyads.com", "adspyglass.com", "clickaine.com",
        "ad-maven.com", "trafficfactory.biz", "trafficfactory.com",
        "exoclick.com", "exosrv.com", "realsrv.com", "juicyads.com",
        "juicyads.net", "trafficjunky.net", "trafficjunky.com",
        "trafficstars.com", "tsyndicate.com", "ero-advertising.com",
        "adnium.com", "push-notifications.com", "exdynsrv.com",
        "magsrv.com", "bngprm.com", "adsco.re", "prpnads.com",
        "ad-delivery.net", "adsafeprotected.com", "moatads.com",
        "doubleverify.com", "amazon-adsystem.com", "media.net",
        "indexexchange.com", "yieldmo.com", "3lift.com", "33across.com",
        "gumgum.com", "sovrn.com", "lijit.com", "advertising.com",
        "zedo.com", "adroll.com", "scorecardresearch.com", "quantserve.com",
        "krxd.net", "bluekai.com", "demdex.net", "everesttech.net",
        "rlcdn.com", "agkn.com", "mathtag.com", "turn.com", "tapad.com",
        "crwdcntrl.net", "exelator.com"
    ]

    static func isAdURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased(), !host.isEmpty else { return false }
        if hosts.contains(host) { return true }
        return hosts.contains { host.hasSuffix("." + $0) }
    }
}
