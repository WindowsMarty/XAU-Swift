import SwiftUI

class ImageCacheService {
    static let shared = ImageCacheService()
    private let cache = NSCache<NSURL, NSImage>()
    
    private init() {}
    
    func getImage(url: URL) async -> NSImage? {
        // Upgrade http to https to satisfy ATS
        var secureURL = url
        if url.scheme == "http" {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.scheme = "https"
            if let upgradedURL = components?.url {
                secureURL = upgradedURL
            }
        }
        
        if let cached = cache.object(forKey: secureURL as NSURL) {
            return cached
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: secureURL)
            if let image = NSImage(data: data) {
                cache.setObject(image, forKey: secureURL as NSURL)
                return image
            }
        } catch {
            print("Failed to download image from \(secureURL): \(error)")
        }
        
        return nil
    }
}

struct CachedAsyncImage: View {
    let url: String?
    @State private var image: NSImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
            } else if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(Image(systemName: "photo").foregroundColor(.secondary))
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let urlString = url, let url = URL(string: urlString) else { return }
        
        isLoading = true
        Task {
            let fetchedImage = await ImageCacheService.shared.getImage(url: url)
            await MainActor.run {
                self.image = fetchedImage
                self.isLoading = false
            }
        }
    }
}
