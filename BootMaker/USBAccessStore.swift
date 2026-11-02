import Foundation

/// Remembers *user-authorized* directories from Files. The bookmark is only an
/// authorization for files. It does not grant raw USB or partition access.
final class USBAccessStore {
    static let shared = USBAccessStore()
    private let key = "BootMaker.authorizedUSBBookmark.v1"

    private init() {}

    func remember(_ url: URL) throws {
        let acquired = url.startAccessingSecurityScopedResource()
        defer { if acquired { url.stopAccessingSecurityScopedResource() } }
        // On iOS a persisted document-picker bookmark retains permission when
        // resolved; .withSecurityScope is macOS-only and intentionally omitted.
        let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        UserDefaults.standard.set(bookmark, forKey: key)
    }

    func lastAuthorizedFolder() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            var stale = false
            let url = try URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &stale)
            if stale { try remember(url) }
            return url
        } catch {
            clear()
            return nil
        }
    }

    func clear() { UserDefaults.standard.removeObject(forKey: key) }
}
