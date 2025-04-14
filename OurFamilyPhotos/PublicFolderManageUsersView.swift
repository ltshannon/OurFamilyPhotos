//
//  PublicFolderManageUsersView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/9/25.
//

import SwiftUI

struct PublicFolderManageUsersView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    var item: PublicFolderInfo
    
    init(parameters: PublicFolderManageUsersParameters) {
        self.item = parameters.item
    }
    
    var body: some View {
        List {
            ForEach(0..<item.userAccessIds.count, id: \.self) { index in
                VStack {
                    Text(getUserName(userId: item.userAccessIds[index]))
                }
            }
        }
        .navigationTitle("Manage Public Folder Users")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {

        }
    }
    
    func getUserName(userId: String) -> String {
        
        let userInfos = firebaseService.userInfos
        let userInfo = userInfos.filter { $0.userId ?? "" == userId }.first
        if let userInfo = userInfo {
            return userInfo.userName ?? "n/a"
        }
        return "n/a"
    }
}
