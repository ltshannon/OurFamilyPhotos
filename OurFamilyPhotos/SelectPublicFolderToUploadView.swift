//
//  SelectPublicFolderToUploadView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/19/25.
//

import SwiftUI

struct SelectPublicFolderToUploadView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss
    @Binding var selectedPublicFolder: PublicFolderInfo?
    
    var body: some View {
        NavigationStack {
            List(firebaseService.publicFolderInfos, children: \.children) { item in
                HStack {
                    Text(item.name)
                    Spacer()
                    Image(systemName: selectedPublicFolder?.name == item.name ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .frame(width: 25, height: 25)
                }
                .onTapGesture {
                    selectedPublicFolder = item
                    dismiss()
                }
            }
            .navigationTitle("Add To A Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
            .onAppear {
                selectedPublicFolder = nil
            }
        }
        
    }
}
