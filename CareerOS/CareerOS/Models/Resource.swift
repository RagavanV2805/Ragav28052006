import Foundation
import SwiftData

/// A structured learning resource attached to a skill. All resource data is
/// stored here — the UI never hard-codes URLs.
@Model
final class Resource {
    var kindRaw: String
    var title: String
    var author: String
    var urlString: String
    var isFree: Bool
    var skill: Skill?

    init(
        kind: ResourceKind,
        title: String,
        author: String = "",
        urlString: String,
        isFree: Bool = true
    ) {
        self.kindRaw = kind.rawValue
        self.title = title
        self.author = author
        self.urlString = urlString
        self.isFree = isFree
    }

    var kind: ResourceKind {
        get { ResourceKind(rawValue: kindRaw) ?? .article }
        set { kindRaw = newValue.rawValue }
    }

    var url: URL? { URL(string: urlString) }

    /// Host name for display, e.g. "developer.mozilla.org".
    var displayHost: String {
        url?.host() ?? urlString
    }
}
