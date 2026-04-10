import Foundation

struct WeatherResponse: Codable, Sendable {
    let name: String
    let main: Main
    let weather: [Weather]
    let wind: Wind
    let sys: Sys
}
struct Sys: Codable, Sendable {
    let sunrise: Double
    let sunset: Double
}

struct Main: Codable, Sendable {
    let temp: Double
    let humidity: Int
    let feels_like: Double
}

struct Weather: Codable, Sendable {
    let description: String
    let icon: String
}

struct Wind: Codable, Sendable {
    let speed: Double
}

struct ForecastResponse: Codable, Sendable {
    let list: [ForecastItem]
}

struct ForecastItem: Codable, Identifiable, Sendable {
    var id: Double { dt }
    let dt: Double          // Zaman damgası
    let main: Main          // Sıcaklık verisi
    let weather: [Weather]  // İkon ve açıklama
    
    // 1. Saat formatı (Saatlik tahmin için)
    var hour: String {
        let date = Date(timeIntervalSince1970: dt)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:00"
        return formatter.string(from: date)
    }
    
    // 2. Gün ismi formatı (5 günlük tahmin için)
    var dayName: String {
        let date = Date(timeIntervalSince1970: dt)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEEE" // Tam gün ismi (Pazartesi vb.)
        return formatter.string(from: date).capitalized
    }
}
