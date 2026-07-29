import Foundation

struct BuildInfo: Equatable, Sendable {
    let version: String
    let build: String
    let gitCommit: String
    let codemagicBuildID: String

    static var current: BuildInfo {
        let info = Bundle.main.infoDictionary ?? [:]
        return BuildInfo(
            version: info["CFBundleShortVersionString"] as? String ?? "unknown",
            build: info["CFBundleVersion"] as? String ?? "unknown",
            gitCommit: info["ChargeGlowGitCommit"] as? String ?? "source",
            codemagicBuildID: info["ChargeGlowCIBuildID"] as? String ?? "local"
        )
    }

    var versionText: String {
        "Version \(version) (\(build))"
    }

    var buildText: String {
        "\(gitCommit) • CI \(codemagicBuildID)"
    }
}
