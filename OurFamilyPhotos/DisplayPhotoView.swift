//
//  DisplayPhotoView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct DisplayPhotoView: View {
    @EnvironmentObject var appNavigationState: AppNavigationState
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var settingsService: SettingsService
    @State var firstTime = true
    @State var showingEditDescriptionAlert = false
    @State var showingMissingPhotoAlert = false
    @State var showingDeleteAlert = false
    @State var showingGetNameAlert = false
    @State var showingAddToPublicFolderSheet = false
    @State var showingNameEmptyAlert = false
    @State var showingFolderExistsAlert = false
    @State var showingFirstTimeAlert = false
    @State var showingAddToFoldersSheet = false
    @State var newDescription = ""
    @State var newFolderName: String = ""
    @State var errorString: String = ""
    @State var selectedItem: PhotoInfo = PhotoInfo(id: "", userfolder: "", description: "", userId: "")
    @State var folderImageURL: URL?
    @State var selectedFolder: PhotoInfo?
    @AppStorage("firstLaunch") var firstLaunch: Bool = true
    let database = Firestore.firestore()
    
    var body: some View {
        NavigationStack(path: $appNavigationState.photosNavigation) {
            List(firebaseService.items, children: \.children) { item in
                HStack {
                    AsyncImage(url: item.children == nil ? item.thumbnailURL : (item.children!.count == 0 ? firebaseService.openFolderImageURL : firebaseService.folderImageURL))  { phase in
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
                    Spacer()
                    Text(item.isFolder ? "" : (item.publicFolders.count > 0 ? "Public" : "Private") )
                }
                .contentShape(Rectangle())
                .swipeActions(allowsFullSwipe: false) {
                    if item.isFolder == false {
                        Button {
                            selectedItem = item
                            showingAddToPublicFolderSheet = true
                        } label: {
                            Text("Access")
                        }
                        .tint(.orange)
                        Button {
                            let parameters = PhotosDetailParameters(item: item)
                            appNavigationState.photosDetailView(parameters: parameters)
                        } label: {
                            Text("Details")
                        }
                        .tint(.cyan)
                    }
                    Button {
                        selectedItem = item
                        newDescription = item.description
                        showingEditDescriptionAlert = true
                    } label: {
                        Text("Edit")
                    }
                    .tint(.indigo)
                    Button(role: .destructive) {
                        selectedItem = item
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
            }
            .navigationTitle("Users Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingGetNameAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.app")
                                .resizable()
                                .scaledToFit()
                        }
                    }
                }
            }
            .navigationDestination(for: PhotosNavDestination.self) { state in
                switch state {
                case .photosDetailView(let parameters):
                    DetailsPhotosView(parameters: parameters)
                }
            }
            .fullScreenCover(isPresented: $showingAddToPublicFolderSheet) {
                AddPhotoToFolder(item: selectedItem, isPublic: true)
            }
            .alert("Create A New Folder", isPresented: $showingGetNameAlert) {
                TextField("", text: $newFolderName)
                    .keyboardType(.default)
                Button("Place In Root") {
                    if newFolderName.isEmpty == true {
                        showingNameEmptyAlert = true
                        return
                    }
                    saveFolderName(parentId: nil)
                }
                Button("Place In Subfolder") {
                    if newFolderName.isEmpty == true {
                        showingNameEmptyAlert = true
                        return
                    }
                    showingAddToFoldersSheet = true
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter a name")
            }
            .alert("Edit Description", isPresented: $showingEditDescriptionAlert) {
                TextField(selectedItem.description, text: $newDescription)
                    .keyboardType(.default)
                Button("OK") {
                    Task {
                        await firebaseService.editDescription(item: selectedItem, newDescription: newDescription)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter a new description")
            }
            .alert("No Image to Display", isPresented: $showingMissingPhotoAlert) {
                Button("Cancel", role: .cancel) { }
            }
            .alert("Are you sure you want to delete this?", isPresented: $showingDeleteAlert) {
                Button("OK", role: .destructive) {
                    Task {
                        await firebaseService.deleteItem(item: selectedItem)
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert(errorString, isPresented: $showingFolderExistsAlert) {
                Button("Cancel", role: .cancel) { }
            }
            .alert("To get started use the '+' button in the top right corner to create your first folder to upload photos too.", isPresented: $showingFirstTimeAlert) {
                Button("Cancel", role: .cancel) { }
            }
            .fullScreenCover(isPresented: $showingAddToFoldersSheet, onDismiss: returnFromSelectFolder) {
                SelectFolderToUploadView(selectedFolder: $selectedFolder)
            }
        }
        .onAppear {
            if firstTime == true {
                Task {
                    await firebaseService.listenerForUserPhotos()
                    await firebaseService.listenerForPublicFolders()
                    await firebaseService.listenerForAccessRequests()
                    await firebaseService.getUserId()
                    await firebaseService.listenerForUsers()
                    firstTime = false
                }
            }
            if firstLaunch == true {
                showingFirstTimeAlert = true
                firstLaunch = false
            }
        }
    }
    
    func returnFromSelectFolder() {
        if let value = selectedFolder {
            saveFolderName(parentId: value.id)
        }
    }
    
    func saveFolderName(parentId: String?) {
        Task {
            if let error = await firebaseService.createFolder(name: newFolderName, folderName: "usersFolders", isPublic: false, parentId: parentId) {
                errorString = error
                showingFolderExistsAlert = true
            }
            newFolderName = ""
        }
    }
    
}
