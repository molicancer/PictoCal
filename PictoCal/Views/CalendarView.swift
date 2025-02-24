import SwiftUI
import Photos

struct CalendarView: View {
    @StateObject private var photoManager = PhotoManager()
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["日", "一", "二", "三", "四", "五", "六"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    Button(action: {
                        // 返回按钮动作
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.red)
                    }
                    
                    Text(yearString)
                        .foregroundColor(.red)
                        .font(.system(size: 18))
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // 月份标题
                Text("\(calendar.component(.month, from: currentMonth))月")
                    .font(.system(size: 32))
                    // .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                
                // 星期行
                HStack(spacing: 0) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(day == "日" || day == "六" ? .red : .primary)
                            .font(.system(size: 12))
                    }
                }
                .padding(.vertical, 10)
                
                // 日历网格
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                    ForEach(getDaysInMonth().indices, id: \.self) { index in
                        if let date = getDaysInMonth()[index] {
                            DayCell(
                                date: date,
                                photos: photoManager.photosByDate[calendar.startOfDay(for: date)] ?? []
                            )
                        } else {
                            Color.clear
                                .frame(height: 88)
                        }
                    }
                }
                .padding(.horizontal, 2)
                
                Spacer()
            }
            .navigationBarHidden(true)
            .background(Color(UIColor.systemBackground))
        }
    }
    
    // 格式化年份显示
    private var yearString: String {
        let year = calendar.component(.year, from: currentMonth)
        return "\(year)年"
    }
    
    // 获取当月的所有日期
    private func getDaysInMonth() -> [Date?] {
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        // 补全最后一周
        let remainingCells = 42 - days.count // 6周 * 7天
        days.append(contentsOf: Array(repeating: nil, count: remainingCells))
        
        return days
    }
}

// 日期单元格视图
struct DayCell: View {
    let date: Date
    let photos: [PHAsset]
    private let calendar = Calendar.current
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // 照片缩略图
            if let image = thumbnailImage {
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .frame(height: 88)
            } else if !photos.isEmpty {
                Color.clear
                    .frame(height: 88)
                    .onAppear {
                        loadThumbnail()
                    }
            }

            // 渐变遮罩层（让日期更容易看清）
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.1),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(thumbnailImage != nil ? 1 : 0)

            // 照片数量指示器
            if photos.count > 0 {
                Text("\(photos.count)")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding([.bottom, .trailing], 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }

            // 日期文字层
            Text("\(calendar.component(.day, from: date))")
                .foregroundColor(thumbnailImage != nil ? .white : (isWeekend(date) ? .red : .primary))
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
        .frame(height: 88)
        .background(
            Color(UIColor.secondarySystemBackground.withAlphaComponent(0.5))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12)) // 将圆角移到最外层
    }
    
    private func isWeekend(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }
    
    private func loadThumbnail() {
        guard let firstPhoto = photos.first else { return }
        
        let size = CGSize(width: 200, height: 200) // 请求更大的尺寸以确保清晰度
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(
            for: firstPhoto,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                self.thumbnailImage = image
            }
        }
    }
}

#Preview {
    CalendarView()
} 
