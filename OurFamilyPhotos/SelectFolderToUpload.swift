//
//  SelectFolderToUpload.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI

struct SelectFolderToUpload: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss
    @Binding var selectedFolder: String
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Select a folder to upload to:")) {
                    ForEach(firebaseService.userFolderNames, id: \.self) { folderName in
                        HStack {
                            Text(folderName)
                            Spacer()
                            Image(systemName: selectedFolder == folderName ? "checkmark.circle.fill" : "circle")
                                .resizable()
                                .frame(width: 25, height: 25)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedFolder = folderName
                            dismiss()
                        }
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
                selectedFolder = ""
            }
        }
        
    }
}
