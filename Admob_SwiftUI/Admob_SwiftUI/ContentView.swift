//
//  ContentView.swift
//  Admob_SwiftUI
//
//  Created by hood on 2023/12/13.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack (alignment: .center, spacing: 20) {
                Spacer(minLength: 0)
                
                HStack (alignment: .center, spacing: 20) {
                    Text("Open Ad")
                    NavigationLink(destination: OpenView()) {
                        Text("Show")
                    }
                }
                
                HStack (alignment: .center, spacing: 20) {
                    Text("Inter Ad")
                    NavigationLink(destination: InterView()) {
                        Text("Show")
                    }
                }
                
                HStack (alignment: .center, spacing: 20) {
                    Text("Native Ad")
                    NavigationLink(destination: NativeView()) {
                        Text("Show")
                    }
                }
                
                HStack (alignment: .center, spacing: 20) {
                    Text("Banner Ad")
                    NavigationLink(destination: BannerView()) {
                        Text("Show")
                    }
                }
                
                HStack (alignment: .center, spacing: 20) {
                    Text("Reward Ad")
                    NavigationLink(destination: RewardView()) {
                        Text("Show")
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
