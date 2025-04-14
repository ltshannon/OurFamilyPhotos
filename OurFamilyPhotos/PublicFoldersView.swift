//
//  PublicFoldersView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct PublicFoldersView: View {
    @EnvironmentObject var appNavigationState: AppNavigationState
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var settingsService: SettingsService
    @State var selectedItem: PublicFolderInfo = PublicFolderInfo(name: "", ownerId: "", userAccessIds: [])
    @State var showingGetNameAlert = false
    @State var showingNameEmptyAlert = false
    @State var showingErrorAlert: Bool = false
    @State var showingDeleteAlert = false
    @State var showingEditDescriptionAlert = false
    @State var showingPublicAutoView = false
    @State var showingNoAccessToFolder = false
    @State var newFolderName: String = ""
    @State var noAccessMessage: String = ""
    @State var forNoAccessUserName = false
    @State var errorString: String = ""
    @State var newName = ""
    @State var firstTime: Bool = true
    @State var userId: String = ""
    let database = Firestore.firestore()
    
    var body: some View {
        NavigationStack(path: $appNavigationState.photosPublicNavigation) {
            List {
                ForEach(0..<firebaseService.publicFolderInfos.count, id: \.self) { index in
                    let item = firebaseService.publicFolderInfos[index]
                    HStack {
                        Text(item.name)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedItem = item
                        if item.userAccessIds.contains(userId) {
                            switch settingsService.puplicPhotoDisplay {
                            case .automaticDisplay:
                                showingPublicAutoView = true
                            case .galleryDisplay:
                                let parameters = PublicPhotosGalleryParameters(item: item)
                                appNavigationState.publicPhotosGalleryView(parameters: parameters)
                            case .carouselDisplay:
                                let parameters = PublicPhotosCarouselParameters(item: item)
                                appNavigationState.publicPhotosCarouselView(parameters: parameters)
                            case .listDisplay:
                                let parameters = PublicPhotosListParameters(item: item)
                                appNavigationState.publicPhotosListView(parameters: parameters)
                            }
                        } else {
                            showingNoAccessToFolder = true
                        }
                    }
                    .swipeActions(allowsFullSwipe: false) {
                        if item.ownerId == Auth.auth().currentUser!.uid {
                            Button {
                                selectedItem = item
                                newName = item.name
                                showingEditDescriptionAlert = true
                            } label: {
                                Text("Edit")
                            }
                            .tint(.indigo)
                            Button {
                                let parameters = PublicFolderManageUsersParameters(item: item)
                                appNavigationState.publicFolderManageUsersView(parameters: parameters)
                            } label: {
                                Text("Manage Users")
                            }
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
            .navigationTitle("Public Photos")
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
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Menu("How To Display Photos") {
                            Button {
                                settingsService.setPuplicPhotoDisplay(puplicPhotoDisplay: .listDisplay)
                            } label: {
                                Label(PuplicPhotoDisplay.listDisplay.rawValue, systemImage: settingsService.puplicPhotoDisplay == .listDisplay ? "checkmark.circle" : "circle")
                            }
                            Button {
                                settingsService.setPuplicPhotoDisplay(puplicPhotoDisplay: .galleryDisplay)
                            } label: {
                                Label(PuplicPhotoDisplay.galleryDisplay.rawValue, systemImage: settingsService.puplicPhotoDisplay == .galleryDisplay ? "checkmark.circle" : "circle")
                            }
                            Button {
                                settingsService.setPuplicPhotoDisplay(puplicPhotoDisplay: .carouselDisplay)
                            } label: {
                                Label(PuplicPhotoDisplay.carouselDisplay.rawValue, systemImage: settingsService.puplicPhotoDisplay == .carouselDisplay ? "checkmark.circle" : "circle")
                            }
                            Button {
                                settingsService.setPuplicPhotoDisplay(puplicPhotoDisplay: .automaticDisplay)
                            } label: {
                                Label(PuplicPhotoDisplay.automaticDisplay.rawValue, systemImage: settingsService.puplicPhotoDisplay == .automaticDisplay ? "checkmark.circle" : "circle")
                            }
                            Menu("Time interval For Carousel Display") {
                                Button {
                                    settingsService.setTimerInterval(timerInterval: TimerInterval.twoSeconds)
                                } label: {
                                    Label("\(TimerInterval.twoSeconds.rawValue) Seconds", systemImage: settingsService.timerInterval == TimerInterval.twoSeconds ? "checkmark.circle" : "circle")
                                }
                                Button {
                                    settingsService.setTimerInterval(timerInterval: TimerInterval.fiveSeconds)
                                } label: {
                                    Label("\(TimerInterval.fiveSeconds.rawValue) Seconds", systemImage: settingsService.timerInterval == TimerInterval.fiveSeconds ? "checkmark.circle" : "circle")
                                }
                                Button {
                                    settingsService.setTimerInterval(timerInterval: TimerInterval.tenSeconds)
                                } label: {
                                    Label("\(TimerInterval.tenSeconds.rawValue) Seconds", systemImage: settingsService.timerInterval == TimerInterval.tenSeconds ? "checkmark.circle" : "circle")
                                }
                            }
                        }
                        Button {
                            
                        } label: {
                            Text("Cancel")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                if firstTime == true {
                    firstTime = false
                    self.userId = firebaseService.userId
                }
            }
            .navigationDestination(for: PublicPhotosNavDestination.self) { state in
                switch state {
                case .publicPhotosListView(let parameters):
                    PublicListView(parameters: parameters)
                case .publicPhotosGalleryView(let parameters):
                    PublicGalleryView(parameters: parameters)
                case .publicPhotosCarouselView(let parameters):
                    PublicCarouselView(parameters: parameters)
                case .publicPhotosTabCarouselView(let parameters):
                    PublicTabCarouselView(parameters: parameters)
                case .publicPhotosDetailView(let parameters):
                    DetailsPhotosView(parameters: parameters)
                case .publicFolderManageUsersView(let parameters):
                    PublicFolderManageUsersView(parameters: parameters)
                }
            }
            .fullScreenCover(isPresented: $showingPublicAutoView) {
                let parameters = PublicPhotosTabCarouselParameters(item: selectedItem)
                PublicTabCarouselView(parameters: parameters)
            }
            .alert("You do not have access to this folder. Enter a message to why you would like access. A request will be sent to the owner, who will grant you access or not. You will be notified either way.", isPresented: $showingNoAccessToFolder) {
                TextField("", text: $noAccessMessage)
                    .keyboardType(.default)
                Button("OK") {
                    if noAccessMessage.isEmpty == true {
                        showingNameEmptyAlert = true
                        forNoAccessUserName = true
                        return
                    }
                    Task {
                        await firebaseService.addAccessRequest(folderName: selectedItem.name, ownerId: selectedItem.ownerId, message: noAccessMessage, state: AccessRequestType.waiting)
                        let userInfos = firebaseService.userInfos
                        let userInfo = userInfos.filter { $0.userId ?? "" == selectedItem.ownerId }.first
                        if let fcm = userInfo?.fcm {
                            let myName = firebaseService.userName
                            let title = "Someone wants to access"
                            let message = "\(myName) wants access to your public folder: \(selectedItem.name)\nReason: \(noAccessMessage)"
                            await firebaseService.callFirebaseCallableFunction(fcm: fcm, title: title, body: message, silent: false)
                        }
                        noAccessMessage = ""
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter a name")
            }
            .alert("Name of Public Folder", isPresented: $showingGetNameAlert) {
                TextField("", text: $newFolderName)
                    .keyboardType(.default)
                Button("OK") {
                    if newFolderName.isEmpty == true {
                        showingNameEmptyAlert = true
                        return
                    }
                    Task {
                        if let error = await firebaseService.createFolder(name: newFolderName, folderName: "publicFolders", isPublic: true) {
                            errorString = error
                            showingErrorAlert = true
                        }
                        newFolderName = ""
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter a name")
            }
            .alert("You need to add a name", isPresented: $showingNameEmptyAlert) {
                Button("Cancel", role: .cancel) {
                    if forNoAccessUserName == true {
                        forNoAccessUserName = false
                        showingNoAccessToFolder = true
                    } else {
                        showingGetNameAlert = true
                    }
                }
            }
            .alert(errorString, isPresented: $showingErrorAlert) {
                Button("Cancel", role: .cancel) { }
            }
            .alert("Are you sure you want to delete this?", isPresented: $showingDeleteAlert) {
                Button("OK", role: .destructive) {
                    Task {
                        await firebaseService.deleteFolder(item: selectedItem)
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert("Edit Description", isPresented: $showingEditDescriptionAlert) {
                TextField(selectedItem.name, text: $newName)
                    .keyboardType(.default)
                Button("OK") {
                    Task {
                        if let error = await firebaseService.editFolderDescription(item: selectedItem, newName: newName) {
                            errorString = error
                            showingErrorAlert = true
                        }
                        newName = ""
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter a new description")
            }
        }
    }
    
}


