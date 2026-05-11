import SwiftUI
import Charts

struct AnalysisView: View {
    @EnvironmentObject var viewModel: AnalysisViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let result = viewModel.analysisResult {
                    AnalysisContentView(result: result)
                } else {
                    ContentUnavailableView(
                        "분석 데이터 없음",
                        systemImage: "chart.bar.xaxis",
                        description: Text("옷을 추가하면 분석 데이터가 표시됩니다.")
                    )
                }
            }
            .navigationTitle("분석")
            .task { await viewModel.loadAnalysis() }
            .refreshable { await viewModel.loadAnalysis() }
        }
    }
}

struct AnalysisContentView: View {
    let result: AnalysisResult

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SummaryCardView(result: result)
                CategoryDistributionCard(data: result.categoryDistribution)
                ColorDistributionCard(data: result.colorDistribution)
                MonthlyExpenditureCard(data: result.monthlyExpenditure)
                LeastWornCard(items: result.leastWornItems)
            }
            .padding()
        }
    }
}

struct SummaryCardView: View {
    let result: AnalysisResult

    var body: some View {
        HStack(spacing: 0) {
            StatItem(value: "\(result.totalPurchaseCount)", label: "총 구매")
            Divider().frame(height: 40)
            StatItem(value: "\(Int(result.totalSpent).formatted())원", label: "총 지출")
            Divider().frame(height: 40)
            StatItem(value: "\(Int(result.averageWearCount))회", label: "평균 착용")
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CategoryDistributionCard: View {
    let data: [(ClothingCategory, Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("카테고리 분포")
                .font(.headline)
            Chart(data, id: \.0) { item in
                BarMark(
                    x: .value("개수", item.1),
                    y: .value("카테고리", item.0.rawValue)
                )
                .foregroundStyle(Color.accentColor)
            }
            .frame(height: CGFloat(data.count) * 30 + 20)
            .chartXAxis(.hidden)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ColorDistributionCard: View {
    let data: [(String, Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("선호 색상")
                .font(.headline)
            Chart(Array(data.prefix(8)), id: \.0) { item in
                SectorMark(
                    angle: .value("개수", item.1),
                    innerRadius: .ratio(0.4)
                )
                .foregroundStyle(by: .value("색상", item.0))
                .annotation(position: .overlay) {
                    Text(item.0)
                        .font(.caption2)
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct MonthlyExpenditureCard: View {
    let data: [(String, Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("월별 지출")
                .font(.headline)
            if data.isEmpty {
                Text("데이터 없음")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(data, id: \.0) { item in
                    BarMark(
                        x: .value("월", item.0),
                        y: .value("금액", item.1)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text("\(Int(amount / 10000))만")
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct LeastWornCard: View {
    let items: [ClothingEntity]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("잘 안 입는 옷")
                .font(.headline)
            if items.isEmpty {
                Text("데이터 없음")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(items) { item in
                    HStack {
                        Image(systemName: "tshirt")
                            .frame(width: 32)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.subheadline)
                            Text(item.brand)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(item.wearCount)회")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
