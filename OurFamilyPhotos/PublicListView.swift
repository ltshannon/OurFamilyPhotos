//
//  PublicListView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct PublicListView: View {
    @EnvironmentObject var appNavigationState: AppNavigationState
    @EnvironmentObject var firebaseService: FirebaseService
    var publicFolder: PublicFolderInfo
    @State var photoInfos: [PhotoInfo] = []
    @State var selectedItem: PhotoInfo?
    @State var showingDeleteAlert = false
    let database = Firestore.firestore()
    
    init(parameters: PublicPhotosListParameters) {
        publicFolder = parameters.item
    }
    
    var body: some View {
        List {
            ForEach(photoInfos, id: \.id) { item in
                HStack {
                    AsyncImage(url: item.thumbnailURL) { phase in
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
                    Text(item.description)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    let parameters = PhotosDetailParameters(item: item)
                    appNavigationState.photosPublicDetailView(parameters: parameters)
                }
                .swipeActions(allowsFullSwipe: false) {
                    if item.userId == Auth.auth().currentUser!.uid {
                        Button(role: .destructive) {
                            selectedItem = item
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                }
            }
        }
        .navigationTitle("Public Folder: \(publicFolder.name)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                photoInfos = await firebaseService.getPhotosForPublicFolder(name: publicFolder.name)
            }
        }
        .alert("Are you sure you want to remove this?", isPresented: $showingDeleteAlert) {
            Button("OK", role: .destructive) {
                Task {
                    if let item = selectedItem {
                        await firebaseService.deletePublicItem(item: item, publicFolder: publicFolder)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
}
