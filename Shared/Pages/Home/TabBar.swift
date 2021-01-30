//
//  TabBar.swift
//  DarkMaps (iOS)
//
//  Created by Matthew Roche on 30/01/2021.
//

import SwiftUI

struct TabBar: View {
    
    @Binding var selectedTab: TabOptions
    
    var body: some View {
        HStack() {
            Spacer()
            TabBarItem(selectedTab: $selectedTab, icon: "list.dash", selection: .list)
            Spacer()
            TabBarItem(selectedTab: $selectedTab, icon: "plus", selection: .newChat)
            Spacer()
            TabBarItem(selectedTab: $selectedTab, icon: "gear", selection: .settings)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TabBarItem: View {
    
    @Binding var selectedTab: TabOptions
    
    var icon: String
    var selection: TabOptions
    
    var body: some View {
        Button(action: {
            withAnimation {
                selectedTab = selection
            }
        }) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(selectedTab == selection ? Color("AccentColor") : Color.gray)
                    .frame(width: 30, height: 30)
            }
            .frame(maxWidth: UIScreen.main.bounds.size.width * 0.2, maxHeight: .infinity)
            .padding(.vertical, 20)
        }
    }
}

struct TabBar_Previews: PreviewProvider {
    
    static var previews: some View {
        return Group {
            PreviewWrapper()
                .previewLayout(.fixed(width: 300 , height: 100))
            PreviewWrapper()
                .previewLayout(.fixed(width: 300 , height: 100))
                .preferredColorScheme(.dark)
        }
    }
    
    struct PreviewWrapper: View {
        
        @State var selectedTab: TabOptions = .list

        var body: some View {
            
            return TabBar(selectedTab: $selectedTab)
        }
    }
    
}
