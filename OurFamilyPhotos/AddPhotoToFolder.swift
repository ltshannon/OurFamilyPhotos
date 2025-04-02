//
//  AddPhotoToFolder.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct AddPhotoToFolder: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss
    var item: PhotoInfo
    var isPublic: Bool
    @State var selectedItem: PublicFolderInfo = PublicFolderInfo(name: "", ownerId: "")
    @State var showingAddPhotoToPublicFolderAlert: Bool = false
    @State var showingRemovingPhotoToPublicFolderAlert: Bool = false
    @State var showingErrorStringAlert = false
    @State var errorString = ""
    @State var photoInfo: PhotoInfo
    let database = Firestore.firestore()
    
    init(item: PhotoInfo, isPublic: Bool) {
        self.item = item
        self.photoInfo = item
        self.isPublic = isPublic
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                AsyncImage(url: item.imageURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                    } else if phase.error != nil {
                        Color.red
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                    }
                }
                .aspectRatio(contentMode: .fit)
                .cornerRadius(8.0)
                Text(item.description)
            }
            .padding([.leading, .trailing], 20)
            List {
                Section(header: Text("Public Folders")) {
                    ForEach(firebaseService.publicFolderInfos, id: \.id) { folderName in
                        HStack {
                            Text(folderName.name)
                            Spacer()
                            Image(systemName: photoInfo.publicFolders.contains(folderName.name) ? "checkmark.circle.fill" : "circle")
                                .resizable()
                                .frame(width: 25, height: 25)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedItem = folderName
                            if photoInfo.publicFolders.contains(folderName.name) {
                                showingRemovingPhotoToPublicFolderAlert = true
                            } else {
                                showingAddPhotoToPublicFolderAlert = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Photo to Public Folder")
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
            .alert("Are you sure you want to add this to \(selectedItem.name) public folder?", isPresented: $showingAddPhotoToPublicFolderAlert) {
                Button("OK", role: .destructive) {
                    Task {
                        errorString = await addToPublicFolder(name: selectedItem.name)
                        if errorString.isEmpty == false {
                            showingErrorStringAlert = true
                        }
                        photoInfo.publicFolders.append(selectedItem.name)
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert("Are you sure you want to remove this from \(selectedItem.name) public folder?", isPresented: $showingRemovingPhotoToPublicFolderAlert) {
                Button("OK", role: .destructive) {
                    Task {
                        errorString = await removeFromPublicFolder(name: selectedItem.name)
                        showingErrorStringAlert = true
                        photoInfo.publicFolders = photoInfo.publicFolders.filter { $0 != selectedItem.name }
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert(errorString, isPresented: $showingErrorStringAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
    
    nonisolated
    func addToPublicFolder(name: String) async -> String {
        
        debugPrint("", "item.id: \(item.id ?? "n/a")")
        guard let docId = item.id else {
            return "Error: No docId for item to add to public folder"
        }
        
        do {
            try await database.collection("allPhotos").document(docId).updateData(["publicFolders": FieldValue.arrayUnion([name])])
        } catch {
            return "Error adding : \(item.id ?? "n/a") to public folder with name: \(name): error: \(error)"
        }
        
        return ""
    }
    
    nonisolated
    func removeFromPublicFolder(name: String) async -> String {
        
        guard let docId = item.id else {
            return "Error: No docId for item to add to public folder"
        }
        
        do {
            try await database.collection("allPhotos").document(docId).updateData(["publicFolders": FieldValue.arrayRemove([name])])
        } catch {
            return "Error removing: \(item.id ?? "n/a") to public folder with name: \(name): error: \(error)"
        }
        
        return "Photo removed from public folder: \(name)"
    }
    
}
