import SwiftUI
import Combine

struct ContentView: View {
    @StateObject var weatherVM = WeatherViewModel()
    @State private var isMenuOpen = false
    @State private var cityInput: String = ""
    @State private var animateGradient = false
    @Environment(\.colorScheme) var colorScheme
    
    // Klavyeyi ve pencereleri kontrol eden durumlar
    @FocusState private var isTextFieldFocused: Bool
    @State private var isHourlyExpanded = false
    @State private var isDailyExpanded = false
    

    var body: some View {
        ZStack {
            // 1. ANA İÇERİK KATMANI
            ZStack {
                // Arka Plan
                RadialGradient(colors: weatherVM.bgColors, center: .center, startRadius: 5, endRadius: 700)
                    .ignoresSafeArea()
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 400, height: 400)
                        .offset(x: -150, y: -250)
                        .blur(radius: 50)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 400, height: 400)
                        .blur(radius: 80)
                        .offset(x: animateGradient ? 100 : -100, y: animateGradient ? 150 : -50)
                }
                .onAppear {
                        withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                            animateGradient.toggle()
                        }
                    }
                
                if weatherVM.description.lowercased().contains("yağmur") ||
                           weatherVM.description.lowercased().contains("kar") {
                            WeatherEffectView(description: weatherVM.description)
                        }
                
                
                VStack(spacing: 15) {
                    // ÜST BAR: Menü ve Favori Ekleme
                    HStack {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                isMenuOpen.toggle()
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button {
                            weatherVM.addCityToFavorites(weatherVM.cityName)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                        }
                    }
                    .padding(.horizontal)

                    // ARAMA ALANI
                    HStack {
                        TextField("Şehir ismi...", text: $cityInput)
                            .padding(12)
                            .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                            .cornerRadius(15)
                            .foregroundColor(.adaptiveText(for: colorScheme))
                            .focused($isTextFieldFocused)
                        
                        Button {
                            weatherVM.fetchWeather(for: cityInput)
                            cityInput = ""
                            isTextFieldFocused = false
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.blue.opacity(0.4))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 25) {
                            // ANA DERECE VE İKON
                            VStack(spacing: 5) {
                                Image(systemName: weatherIconName(icon: weatherVM.weatherIcon))
                                    .symbolRenderingMode(.multicolor)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 140, height: 140)
                                    .symbolEffect(.bounce, value: weatherVM.temperature)
                                
                                Text(weatherVM.cityName)
                                    .font(.system(size: 35, weight: .bold, design: .rounded))
                                
                                Text(weatherVM.temperature)
                                    .font(.system(size: 90, weight: .thin, design: .rounded))
                                
                                Text(weatherVM.description)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 5)
                                    .background(.white.opacity(0.1))
                                    .cornerRadius(15)
                            }
                            .foregroundColor(.white)
                            
                            HStack(spacing: 15) {
                                Image(systemName: "sparkles") // Yapay zeka efekti veren ikon
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                                
                                Text(weatherVM.aiAdvice)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .padding(.top, 10)

                            // SAATLİK TAHMİN (Açılır Pencere)
                            ExpandableSection(title: "Saatlik Tahmin", icon: "clock.fill", isExpanded: $isHourlyExpanded) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(weatherVM.hourlyForecast) { item in
                                            VStack(spacing: 8) {
                                                Text(item.hour).font(.caption2).bold()
                                                Image(systemName: weatherIconName(icon: item.weather.first?.icon ?? ""))
                                                    .symbolRenderingMode(.multicolor)
                                                Text("\(Int(item.main.temp))°").font(.callout).bold()
                                            }
                                            .padding()
                                            .background(.white.opacity(0.1))
                                            .cornerRadius(15)
                                        }
                                    }
                                    .padding([.horizontal, .bottom])
                                }
                            }

                            // 5 GÜNLÜK TAHMİN (Açılır Pencere)
                            ExpandableSection(title: "5 Günlük Tahmin", icon: "calendar", isExpanded: $isDailyExpanded) {
                                VStack(spacing: 12) {
                                    ForEach(weatherVM.dailyForecast.prefix(5)) { day in
                                        HStack {
                                            Text(day.dayName).frame(width: 90, alignment: .leading)
                                            Spacer()
                                            Image(systemName: weatherIconName(icon: day.weather.first?.icon ?? ""))
                                                .symbolRenderingMode(.multicolor)
                                            Spacer()
                                            Text("\(Int(day.main.temp))°").bold().frame(width: 40, alignment: .trailing)
                                        }
                                        if day.id != weatherVM.dailyForecast.prefix(5).last?.id {
                                            Divider().background(.white.opacity(0.2))
                                        }
                                    }
                                }
                                .padding([.horizontal, .bottom])
                            }
                            
                            
                            // ALT DETAYLAR (Nem & Rüzgar)
                            HStack(spacing: 20) {
                               
                                
                                DetailCardView(
                                        title: "HİSS",
                                        value: weatherVM.feelsLike,
                                        icon: "thermometer.medium",
                                        showBar: true,
                                        currentTemp: weatherVM.rawTemp,
                                        feelsLikeTemp: weatherVM.rawFeelsLike
                                    )
                                      .frame(width: 100)
                                DetailCardView(title: "NEM", value: weatherVM.humidity, icon: "humidity.fill")
                                    .frame(width: 100)
                                DetailCardView(
                                        title: "RÜZGAR",
                                        value: weatherVM.windSpeed,
                                        icon: "wind",
                                        isWindCard: true,
                                        windSpeed: Double(weatherVM.windSpeed.replacingOccurrences(of: " m/s", with: "")) ?? 0
                                    )
                                .frame(width: 100)
                                
                                SunCardView(sunrise: weatherVM.sunrise, sunset: weatherVM.sunset)
                                .frame(width: 100)
                            }
                            .padding(.horizontal)
                            
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .offset(x: isMenuOpen ? 280 : 0)
            .scaleEffect(isMenuOpen ? 0.9 : 1)
            .disabled(isMenuOpen)
            
            // 2. KARARTMA KATMANI
            if isMenuOpen {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { isMenuOpen = false }
                    }
            }

            // 3. YAN MENÜ KATMANI
            HStack {
                SideMenuView(weatherVM: weatherVM, isMenuOpen: $isMenuOpen)
                    .offset(x: isMenuOpen ? 0 : -280)
                Spacer()
            }
        }
        .onTapGesture { isTextFieldFocused = false }
    }

    // İkon Fonksiyonu
    func weatherIconName(icon: String) -> String {
        switch icon {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.stars.fill"
        case "02d", "02n": return "cloud.sun.fill"
        case "03d", "04d": return "cloud.fill"
        case "09d", "10d": return "cloud.heavyrain.fill"
        case "11d": return "cloud.bolt.fill"
        case "13d": return "snow"
        case "50d": return "cloud.fog.fill"
        default: return "thermometer.medium"
        }
    }
}

// --- YARDIMCI GÖRÜNÜMLER ---

struct SideMenuView: View {
    @ObservedObject var weatherVM: WeatherViewModel
    @Binding var isMenuOpen: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Şehirlerim")
                .font(.largeTitle).bold()
                .padding(.top, 60).padding(.horizontal)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            List {
                ForEach(weatherVM.favoriteCities, id: \.self) { city in
                    Button {
                        weatherVM.fetchWeather(for: city)
                        withAnimation { isMenuOpen = false }
                    } label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                            Text(city).font(.headline)
                        }
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                    }
                    .listRowBackground(Color.clear)
                }
                .onDelete(perform: weatherVM.removeCity)
            }
            .listStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: 280)
        .background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.8))
            .background(.ultraThinMaterial)
        .edgesIgnoringSafeArea(.all)
    }
}

struct ExpandableSection<Content: View>: View {
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    let content: () -> Content
    
    var body: some View {
        VStack {
            Button {
                withAnimation(.spring()) { isExpanded.toggle() }
            } label: {
                HStack {
                    Label(title, systemImage: icon).font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .foregroundColor(.white)
                .padding()
            }
            
            if isExpanded {
                content()
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal)
    }
}

struct DetailCardView: View {
    var title: String
    var value: String
    var icon: String
    var showBar: Bool = false
    var currentTemp: Double = 0
    var feelsLikeTemp: Double = 0
    
    // Rüzgar animasyonu için eklenenler
    var isWindCard: Bool = false
    var windSpeed: Double = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                // Eğer rüzgar kartıysa dönme efekti ekle
                .rotationEffect(.degrees(isWindCard ? rotation : 0))
            
            Text(title).font(.caption2).fontWeight(.black).opacity(0.6)
            Text(value).font(.headline)
            
            if showBar {
                // ... Mevcut bar kodların
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.2)).frame(height: 6)
                    Capsule()
                        .fill(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                        .frame(width: calculateBarWidth(), height: 6)
                }
                .padding(.horizontal, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .foregroundColor(.white)
        .onAppear {
            if isWindCard {
                // Rüzgar hızı arttıkça süreyi (duration) azaltıyoruz ki daha hızlı dönsün
                // Örn: 10 m/s hızda 1 saniyede tur atar, 2 m/s hızda 5 saniyede.
                let speedFactor = max(0.5, 5.0 - (windSpeed / 5.0))
                
                withAnimation(.linear(duration: speedFactor).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
    }
    
    // Basit bir oran hesaplama (Örn: -10 ile 40 derece arası bir skala)
    func calculateBarWidth() -> CGFloat {
        let minTemp: Double = -10
        let maxTemp: Double = 40
        let range = maxTemp - minTemp
        let progress = (feelsLikeTemp - minTemp) / range
        return CGFloat(max(0, min(1, progress))) * 60 // 60 kartın iç genişliği baz alınmıştır
    }
}

struct SunCardView: View {
    let sunrise: Double
    let sunset: Double
    
    // Güneşin şu anki konumu (0.0 ile 1.0 arasında)
    var progress: Double {
        let now = Date().timeIntervalSince1970
        guard now > sunrise else { return 0 }
        if now > sunset { return 1 }
        return (now - sunrise) / (sunset - sunrise)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("GÜNEŞ").font(.caption2).fontWeight(.black).opacity(0.6)
            
            ZStack {
                // Yarım Daire Yol
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [3, 3]))
                    .frame(width: 50, height: 50)
                
                // Güneş İkonu (Yol üzerinde hareket eder)
                GeometryReader { geo in
                    let angle = .pi + (progress * .pi)
                    let radius = geo.size.width / 2
                    let x = geo.size.width / 2 + cos(CGFloat(angle)) * radius
                    let y = geo.size.height + sin(CGFloat(angle)) * radius
                    
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow, radius: 2)
                        .position(x: x, y: y)
                }
                .frame(width: 50, height: 25) // Yükseklik genişliğin yarısı
            }
            .frame(height: 30) // Kart içindeki alan
            
            Text(formatTime(sunset))
                .font(.system(size: 14, weight: .bold))
            
            Text("Batış")
                .font(.system(size: 10))
                .opacity(0.6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100) // Diğer kartlarla aynı boy
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .foregroundColor(.white)
    }
    
    func formatTime(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
struct WeatherParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var velocity: CGFloat
    var opacity: Double
}
struct WeatherEffectView: View {
    var description: String
    @State private var particles: [WeatherParticle] = []
    let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    if description.lowercased().contains("yağmur") {
                        // Yağmur Damlası
                        Capsule()
                            .fill(Color.white.opacity(particle.opacity))
                            .frame(width: 1, height: 15)
                            .position(x: particle.x, y: particle.y)
                    } else if description.lowercased().contains("kar") {
                        // Kar Tanesi
                        Circle()
                            .fill(Color.white.opacity(particle.opacity))
                            .frame(width: 4, height: 4)
                            .blur(radius: 1)
                            .position(x: particle.x, y: particle.y)
                    }
                }
            }
            .onAppear { createInitialParticles(in: geo.size) }
            .onReceive(timer) { _ in updateParticles(in: geo.size) }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false) // Tıklamaları engellemez, arkadaki butonlar çalışır
    }
    
    // İlk parçacıkları oluştur
    func createInitialParticles(in size: CGSize) {
        for _ in 0..<40 {
            particles.append(WeatherParticle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -size.height...0),
                velocity: CGFloat.random(in: 10...20),
                opacity: Double.random(in: 0.2...0.5)
            ))
        }
    }
    
    // Parçacıkları aşağı kaydır ve yukarıdan geri başlat
    func updateParticles(in size: CGSize) {
        for i in 0..<particles.count {
            particles[i].y += particles[i].velocity
            if particles[i].y > size.height + 20 {
                particles[i].y = -20
                particles[i].x = CGFloat.random(in: 0...size.width)
            }
        }
    }
}

extension Color {
    static func adaptiveText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.2)
    }
    
    static func adaptiveGlass(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.2)
    }
}
