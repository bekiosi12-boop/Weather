import Foundation
import SwiftUI
import Combine

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var cityName: String = "Şehir Ara"
    @Published var temperature: String = "--"
    @Published var description: String = ""
    @Published var weatherIcon: String = ""
    @Published var humidity: String = "--"
    @Published var sunrise: Double = 0.0
    @Published var sunset: Double = 0.0
    @Published var windSpeed: String = "--"
    @Published var feelsLike: String = "--"
    @Published var rawTemp: Double = 0.0
    @Published var rawFeelsLike: Double = 0.0
    @Published var hourlyForecast: [ForecastItem] = []
    @Published var dailyForecast: [ForecastItem] = []
    @Published var favoriteCities: [String] = ["İstanbul", "Ankara", "Londra"]
    @Published var aiAdvice: String = "Veriler analiz ediliyor..."
   
    
    
    // Hava durumuna göre dinamik renkler
    @Published var bgColors: [Color] = [.blue, .cyan]
    
    private let apiKey = "c6990995b3f4e2ecfbd43823c2e94cbd" // BURAYA KENDİ ANAHTARINI YAZ
    
    func fetchWeather(for city: String) {
        Task {
            let formattedCity = city.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? city
            let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(formattedCity)&appid=\(apiKey)&units=metric&lang=tr"
            
            guard let url = URL(string: urlString) else { return }
            
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    self.cityName = "Hata: \(httpResponse.statusCode)"
                    return
                }
                
                let decodedData = try JSONDecoder().decode(WeatherResponse.self, from: data)
                
                // Verileri eşitle
                self.cityName = decodedData.name
                self.temperature = String(format: "%.0f°", decodedData.main.temp)
                self.description = decodedData.weather.first?.description.capitalized ?? ""
                self.humidity = "%\(decodedData.main.humidity)"
                self.windSpeed = "\(decodedData.wind.speed) m/s"
                self.weatherIcon = decodedData.weather.first?.icon ?? ""
                self.feelsLike = String(format: "%.0f°", decodedData.main.feels_like)
                self.generateAdvice(temp: decodedData.main.temp, description: decodedData.weather.first?.description ?? "", wind: decodedData.wind.speed)
                self.rawTemp = decodedData.main.temp
                self.rawFeelsLike = decodedData.main.feels_like
                self.fetchForecast(for: city)
                self.sunrise = decodedData.sys.sunrise
                self.sunset = decodedData.sys.sunset
                self.generateAdvice(
                temp: decodedData.main.temp,
                description: decodedData.weather.first?.description ?? "",
                wind: decodedData.wind.speed
                    )
                
                
                // Arka plan rengini güncelle
                updateTheme(desc: decodedData.weather.first?.description ?? "")
                
                
            } catch {
                self.cityName = "Şehir Bulunamadı"
            }
        }
    }
    
    func fetchForecast(for city: String) {
        Task {
            let formattedCity = city.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? city
            let urlString = "https://api.openweathermap.org/data/2.5/forecast?q=\(formattedCity)&appid=\(apiKey)&units=metric&lang=tr"
            
            guard let url = URL(string: urlString) else { return }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decodedData = try JSONDecoder().decode(ForecastResponse.self, from: data)
                
                // Sadece ilk 8 tahmini alalım (yaklaşık 24 saatlik dilim)
                self.hourlyForecast = Array(decodedData.list.prefix(8))
                self.dailyForecast = decodedData.list.filter { $0.hour == "12:00" || $0.hour == "15:00" }
            } catch {
                print("Tahmin verisi alınamadı: \(error)")
            }
        }
    }
    func addCityToFavorites(_ city: String) {
        let trimmedCity = city.trimmingCharacters(in: .whitespaces)
        if !trimmedCity.isEmpty && !favoriteCities.contains(trimmedCity) {
            favoriteCities.append(trimmedCity)
        }
    }

    func removeCity(at offsets: IndexSet) {
        favoriteCities.remove(atOffsets: offsets)
    }
    
    func generateAdvice(temp: Double, description: String, wind: Double) {
        let desc = description.lowercased()
        
        // Çoklu koşullarla daha zengin mesajlar
        switch (temp, desc, wind) {
        case (_, let d, _) where d.contains("kar"):
            aiAdvice = "Kar taneleri yolda! ❄️ Kalın çoraplarını giymeyi unutma."
        case (let t, _, _) where t < 5:
            aiAdvice = "Hava dondurucu! 🧤 Atkı ve eldiven kombinasyonu bugün şart."
        case (_, _, let w) where w > 15:
            aiAdvice = "Dikkat! 💨 Rüzgar çok sert, uçuşan objelere karşı tedbirli ol."
        case (20...28, let d, _) where d.contains("açık"):
            aiAdvice = "Tam bir kahve içip yürüyüş yapma havası! ☕️ Tadını çıkar."
        default:
            aiAdvice = "Veriler analiz edildi: Bugün her şey yolunda görünüyor! ✨"
        }
    }
    
    private func updateTheme(desc: String) {
        let d = desc.lowercased()
        
        withAnimation(.easeInOut(duration: 1.0)) {
            if d.contains("güneş") || d.contains("açık") {
                // Daha canlı bir gün ışığı teması
                bgColors = [Color.yellow, Color.orange, Color.blue]
            } else if d.contains("yağmur") || d.contains("fırtına") {
                // Derin lacivert ve koyu mavi fırtına teması
                bgColors = [Color(red: 0.05, green: 0.1, blue: 0.3), Color.blue]
            } else if d.contains("bulut") {
                // Modern gri-mavi bulutlu hava
                bgColors = [Color(red: 0.4, green: 0.5, blue: 0.7), Color(red: 0.2, green: 0.3, blue: 0.5)]
            } else {
                // Standart canlı tema
                bgColors = [Color.purple, Color.indigo, Color.blue]
            }
        }
    }
}
