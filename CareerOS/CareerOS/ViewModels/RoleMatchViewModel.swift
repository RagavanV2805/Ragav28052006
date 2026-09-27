import Foundation
import SwiftData
import Observation

/// Role Match: transparent, weighted coverage of every role based on the
/// skills the user already has. Not a judgement — an arithmetic snapshot.
@Observable
final class RoleMatchViewModel {
    private(set) var state: ViewState<[RoleMatch]> = .loading

    func load(context: ModelContext) async {
        state = .loading
        let matches = RoadmapService(context: context).roleMatches()
        state = .loaded(matches)
    }

    func setTargetRole(slug: String, context: ModelContext) {
        let profile = PersistenceService.profile(in: context)
        profile.targetRoleSlug = slug
        try? context.save()
        WidgetSnapshotPublisher.publish(context: context)
    }
}
