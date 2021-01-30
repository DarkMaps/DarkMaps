//
//  TabHolder.swift
//  DarkMaps (iOS)
//
//  Created by Matthew Roche on 30/01/2021.
//

import SwiftUI

struct TabHolder: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @State var selectedTab: TabOptions = .list
    
    var calculatedListX: CGFloat {
        let width = UIScreen.main.bounds.size.width
        switch selectedTab {
        case .list:
            return 0
        default:
            return -width
        }
    }
    
    var calculatedNewMessageX: CGFloat {
        let width = UIScreen.main.bounds.size.width
        switch selectedTab {
        case .list:
            return width
        case .newChat:
            return 0
        case .settings:
            return -width
        }
    }
    
    var calculatedSettingsX: CGFloat {
        let width = UIScreen.main.bounds.size.width
        switch selectedTab {
        case .settings:
            return 0
        default:
            return width
        }
    }
    
    var calculatedCircleX: CGFloat {
        let width = (UIScreen.main.bounds.size.width) / 3.35
        switch selectedTab {
        case .list:
            return -width
        case .newChat:
            return 0
        case .settings:
            return width
        }
    }
    
    
    var body: some View {
        VStack(alignment: .center) {
            ZStack {
                ListController()
                    .offset(x: calculatedListX)
                    .animation(.easeInOut(duration: 0.2))
                NewChatController()
                    .offset(x: calculatedNewMessageX)
                    .animation(.easeInOut(duration: 0.2))
                SettingsController()
                    .offset(x: calculatedSettingsX)
                    .animation(.easeInOut(duration: 0.2))
            }
            ZStack {
                Capsule()
                    .foregroundColor(colorScheme == .dark ? Color.black : Color(UIColor.systemGray3))
                    .frame(width: 60, height: 45)
                    .offset(x: calculatedCircleX)
                    .animation(.interpolatingSpring(mass: 0.8, stiffness: 400, damping: 20, initialVelocity: 1))
                TabBar(selectedTab: $selectedTab)
                    .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.size.height * 0.08)
            }
            .background(Color(UIColor.systemGray6))
            .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(Color.gray), alignment: .top)
        }
        
        
    }
}

enum TabOptions {
    case list, newChat, settings
}

struct TabHolder_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TabHolder().environmentObject(AppState())
            TabHolder().preferredColorScheme(.dark).environmentObject(AppState())
        }
    }
}
