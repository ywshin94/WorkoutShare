//
//  SettingsView.swift
//  WorkoutShare
//
//  Created by 신용운 on 7/3/25.
//


import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var stravaService: StravaService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingLogoutConfirm = false

    // 앱 버전과 빌드 번호를 가져오는 헬퍼
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
    }

    var body: some View {
        NavigationStack {
            Form {
                // 섹션 1: 앱 정보
                Section(header: Text("앱 정보")) {
                    HStack {
                        Text("앱 버전")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("빌드 번호")
                        Spacer()
                        Text(buildNumber)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 섹션 2: 계정 관리
                Section(header: Text("계정")) {
                    Button(role: .destructive) {
                        showingLogoutConfirm = true
                    } label: {
                        Text("Strava 연결 해제")
                    }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Strava 연결 해제", isPresented: $showingLogoutConfirm, titleVisibility: .visible) {
                Button("연결 해제", role: .destructive) {
                    Task {
                        await stravaService.deauthorize()
                        dismiss() // 로그아웃 후 설정 창 닫기
                    }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("앱과 Strava의 연결을 해제하고 로그아웃합니다. 이 동작은 되돌릴 수 없습니다.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(StravaService())
}
