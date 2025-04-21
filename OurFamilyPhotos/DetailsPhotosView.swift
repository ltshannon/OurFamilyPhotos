//
//  DetailsPhotosView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import AVKit
import PDFKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct DetailsPhotosView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State var selectedItem: PublicFolderInfo = PublicFolderInfo(name: "", ownerId: "", userAccessIds: [])
    @State var showingAddPhotoToPublicFolderAlert = false
    @State var showingRemovingPhotoToPublicFolderAlert = false
    @State var showingErrorStringAlert = false
    @State var errorString = ""
    var externalDataService = ExternalDataService.shared
    @State var item: PhotoInfo
    let database = Firestore.firestore()
    
    init(parameters: PhotosDetailParameters) {
        item = parameters.item
    }
    
    var body: some View {
        ZStack {
            Color("Background-grey").edgesIgnoringSafeArea(.all)
            VStack {
                if (item.uploadFileType == nil || item.uploadFileType == .images), let url = item.imageURL {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image, externalDataService.updateImage(image: image) {
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
                } else if item.uploadFileType == .videos, let url = item.imageURL  {
                    VideoPlayer(player: AVPlayer(url: url))
                        .scaledToFit()
                        .cornerRadius(8.0)
                } else if let url = item.imageURL, let pdfDoc = PDFDocument(url: url) {
                    PDFKitView(showing: pdfDoc)
                        .scaledToFit()
                }
                
                List {
                    Section {
                        Text(item.description)
                    } header: {
                        Text("Description")
                    }
                    Section {
                        Text(getUserName(userId: item.userId))
                    } header: {
                        Text("Owner")
                    }
                }
                .contentMargins(.bottom, 0)
                List(firebaseService.publicFolderInfos, children: \.children) { folderName in
                    HStack {
                        Text(folderName.name)
                        Spacer()
                        Image(systemName: item.publicFolders.contains(folderName.name) ? "checkmark.circle.fill" : "circle")
                            .resizable()
                            .frame(width: 25, height: 25)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if item.userId == Auth.auth().currentUser!.uid {
                            selectedItem = folderName
                            if item.publicFolders.contains(folderName.name) {
                                showingRemovingPhotoToPublicFolderAlert = true
                            } else {
                                showingAddPhotoToPublicFolderAlert = true
                            }
                        }
                    }
                }
                .contentMargins(.top, 0)
            }
            .padding([.leading, .trailing], 20)
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
            .alert(errorString, isPresented: $showingErrorStringAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
    
    func getUserName(userId: String) -> String {
        if let name = firebaseService.userInfos.filter( {$0.userId == userId} ).first {
            return name.userName ?? "n/a"
        }
        return "n/a"
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
