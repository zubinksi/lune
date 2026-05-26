import Foundation

enum ProxyConfig {
    // After deploying the Cloudflare Worker, paste its URL here.
    // e.g. "https://ona-proxy.your-subdomain.workers.dev"
    static let proxyURL = "https://ona-proxy.your-subdomain.workers.dev"

    // If you set the ONA_SECRET wrangler secret, put the same value here.
    // Leave empty string if you skipped that step.
    static let proxySecret = ""
}
