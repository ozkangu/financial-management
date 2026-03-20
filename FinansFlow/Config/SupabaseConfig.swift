import Foundation
import Supabase

enum SupabaseConfig {
    static let url: URL = {
        guard let urlString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
              let url = URL(string: urlString) else {
            // Fallback for development - will be overridden by xcconfig
            return URL(string: "https://placeholder.supabase.co")!
        }
        return url
    }()

    static let anonKey: String = {
        guard let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String else {
            return "placeholder-key"
        }
        return key
    }()

    static let client = SupabaseClient(
        supabaseURL: url,
        supabaseKey: anonKey
    )
}
