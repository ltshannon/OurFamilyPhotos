//
//  PublicFolderHierarchyView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/22/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct PublicFolderHierarchyView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss
    @State var showingRemovingPhotoToPublicFolderAlert = false
    @State var showingAddPhotoToPublicFolderAlert = false
    @State var showingErrorStringAlert = false
    @State var errorString = ""
    @State var selectedItem: PublicFolderInfo = PublicFolderInfo(ownerId: "", userAccessIds: [], children: [])
    @Binding var item: PhotoInfo
    let database = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            List(firebaseService.publicFolderInfos, children: \.children) { folderName in
                HStack {
                    AsyncImage(url: firebaseService.folderImageURL)  { phase in
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
                    .frame(height: 75)
                    .cornerRadius(8.0)
                    Text(folderName.name)
                    Spacer()
                    Image(systemName: item.publicFolders.contains(folderName.name) ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .frame(width: 25, height: 25)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedItem = folderName
                    if item.publicFolders.contains(folderName.name) {
                        showingRemovingPhotoToPublicFolderAlert = true
                    } else {
                        showingAddPhotoToPublicFolderAlert = true
                    }
                }
            }
            .navigationTitle("Manage Public Folder")
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
            .alert("Are you sure you want to remove this from \(selectedItem.name) public folder?", isPresented: $showingRemovingPhotoToPublicFolderAlert) {
                Button("OK", role: .destructive) {
                    Task {
                        errorString = await removeFromPublicFolder(name: selectedItem.name)
                        showingErrorStringAlert = true
                        item.publicFolders = item.publicFolders.filter { $0 != selectedItem.name }
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert("Are you sure you want to add this to \(selectedItem.name) public folder?", isPresented: $showingAddPhotoToPublicFolderAlert) {
                Button("OK", role: .destructive) {
                    Task {
                        errorString = await addToPublicFolder(name: selectedItem.name)
                        if errorString.isEmpty == false {
                            showingErrorStringAlert = true
                        }
                        item.publicFolders.append(selectedItem.name)
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
        
        debugPrint("", "item.id: \(await item.id ?? "n/a")")
        guard let docId = await item.id else {
            return "Error: No docId for item to add to public folder"
        }
        
        do {
            try await database.collection("allPhotos").document(docId).updateData(["publicFolders": FieldValue.arrayUnion([name])])
        } catch {
            return "Error adding : \(await item.id ?? "n/a") to public folder with name: \(name): error: \(error)"
        }
        
        return ""
    }
    
    nonisolated
    func removeFromPublicFolder(name: String) async -> String {
        
        guard let docId = await item.id else {
            return "Error: No docId for item to add to public folder"
        }
        
        do {
            try await database.collection("allPhotos").document(docId).updateData(["publicFolders": FieldValue.arrayRemove([name])])
        } catch {
            return "Error removing: \(await item.id ?? "n/a") to public folder with name: \(name): error: \(error)"
        }
        
        return "Photo removed from public folder: \(name)"
    }
}
