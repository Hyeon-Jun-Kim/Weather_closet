import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @State private var showEditSheet = false
    @State private var showAddMeasurementSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 72, height: 72)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.title)
                                    .foregroundStyle(Color.accentColor)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.user?.nickname ?? "닉네임 미설정")
                                .font(.title2)
                                .fontWeight(.bold)
                            Button("프로필 편집") { showEditSheet = true }
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("신체 정보") {
                    if let latest = viewModel.bodyMeasurements.first {
                        InfoRow(label: "키", value: "\(Int(latest.height))cm")
                        InfoRow(label: "몸무게", value: "\(String(format: "%.1f", latest.weight))kg")
                        InfoRow(label: "측정일", value: latest.recordedAt.formatted(date: .abbreviated, time: .omitted))
                    } else {
                        Text("신체 정보가 없습니다.")
                            .foregroundStyle(.secondary)
                    }
                    Button("신체 정보 추가") { showAddMeasurementSheet = true }
                }

                if viewModel.bodyMeasurements.count > 1 {
                    Section("측정 기록") {
                        ForEach(viewModel.bodyMeasurements) { m in
                            HStack {
                                Text(m.recordedAt.formatted(date: .abbreviated, time: .omitted))
                                Spacer()
                                Text("\(Int(m.height))cm / \(String(format: "%.1f", m.weight))kg")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("프로필")
            .task { await viewModel.loadProfile() }
            .sheet(isPresented: $showEditSheet) {
                EditProfileView().environmentObject(viewModel)
            }
            .sheet(isPresented: $showAddMeasurementSheet) {
                AddMeasurementView().environmentObject(viewModel)
            }
        }
    }
}

struct EditProfileView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var nickname = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("닉네임") {
                    TextField("닉네임", text: $nickname)
                }
            }
            .navigationTitle("프로필 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task {
                            await viewModel.updateProfile(
                                nickname: nickname,
                                profileImageURL: viewModel.user?.profileImageURL
                            )
                            dismiss()
                        }
                    }
                }
            }
            .onAppear { nickname = viewModel.user?.nickname ?? "" }
        }
    }
}

struct AddMeasurementView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var height = ""
    @State private var weight = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("신체 정보") {
                    HStack {
                        TextField("키", text: $height)
                            .keyboardType(.decimalPad)
                        Text("cm")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        TextField("몸무게", text: $weight)
                            .keyboardType(.decimalPad)
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("신체 정보 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        guard let h = Double(height), let w = Double(weight) else { return }
                        Task {
                            await viewModel.addBodyMeasurement(height: h, weight: w)
                            dismiss()
                        }
                    }
                    .disabled(height.isEmpty || weight.isEmpty)
                }
            }
        }
    }
}
