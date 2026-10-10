//
//  ContentView.swift
//  CampusMate
//
//  Created by Ashen Sudaraka on 2026-10-09.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if !authViewModel.hasCheckedSession {
                ProgressView()
            } else if authViewModel.isSignedIn {
                SignedInView(authViewModel: authViewModel)
            } else {
                AuthFlowView(viewModel: authViewModel)
            }
        }
        .animation(.default, value: authViewModel.isSignedIn)
    }
}
