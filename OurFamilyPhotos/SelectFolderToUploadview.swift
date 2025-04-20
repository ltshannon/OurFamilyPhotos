//
//  SelectFolderToUploadView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI

struct SelectFolderToUploadView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss
    @Binding var selectedFolder: PhotoInfo?
    
    var body: some View {
        NavigationStack {
            List(firebaseService.folders, children: \.children) { item in
                if item.isFolder == true {
                    HStack {
                        Text(item.description)
                        Spacer()
                        Image(systemName: selectedFolder?.description == item.description ? "checkmark.circle.fill" : "circle")
                            .resizable()
                            .frame(width: 25, height: 25)
                    }
                    .onTapGesture {
                        selectedFolder = item
                        dismiss()
                    }
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
                selectedFolder = nil
            }
        }
        
    }
}
