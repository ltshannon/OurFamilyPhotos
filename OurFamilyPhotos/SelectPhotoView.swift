//
//  SelectPhotoView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import PhotosUI

struct SelectPhotoView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var settingsService: SettingsService
    @State var selectedPhotos: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State var imagesData: [Data] = []
    @State var fileUploadFailedMessage = ""
    @State var showingUploadError = false
    @State var showingSuccess = false
    @State var showingCanNotDownloadImage = false
    @State var showingUploadButton: Bool = false
    @State var showingUploadFolderMissing: Bool = false
    @State var isButtonDisabled: Bool = false
    @State var isUploadButtonDisabled: Bool = true
    @State var progress: Double?
    @State var newPhoto: PhotoInfo = PhotoInfo(userfolder: "", userId: "")
    @State var uploadPhotoCount = 0
    @State var uploadPhotoOriginalCount = 0
    @State var showingAddToFoldersSheet = false
    @State var selectedFolder: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background-grey").edgesIgnoringSafeArea(.all)
                VStack {
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(0..<images.count, id: \.self) { index in
                                Image(uiImage: images[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                            }
                        }
                    }
                    
                    if let progress = progress {
                        ProgressView(value: progress, total: 1) {
                            Text("Uploading photo \(uploadPhotoCount) of \(uploadPhotoOriginalCount)")
                        } currentValueLabel: {
                            Text(progress.formatted(.percent.precision(.fractionLength(0))))
                        }
                    }
                    PhotosPicker(selection: $selectedPhotos,
                                 maxSelectionCount: settingsService.uploadFileType == .images ? 10 : 1,
                                 matching: settingsService.uploadFileType == .images ? .images : .videos,
                                 photoLibrary: .shared()) {
                        Text("Get a photo from your library")
                            .DefaultTextButtonStyle()
                    }
                    .disabled(isButtonDisabled)
                    if showingUploadButton == true {
                        Button {
                            showingAddToFoldersSheet = true
                        } label: {
                            Text("Upload photo")
                        }
                        .DefaultTextButtonStyle()
                        .disabled(isButtonDisabled)
                    }
                }
                .task(id: selectedPhotos) {
                    var images: [UIImage?] = []
                    var imagesData: [Data?] = []
                    for selectedPhoto in selectedPhotos {
                        let data = try? await selectedPhoto.loadTransferable(type: Data.self)
                        if data != nil {
                            var image: UIImage?
                            switch settingsService.uploadFileType {
                            case .images:
                                image = UIImage(data: data!)
                            case .videos:
                                image = UIImage(named: "movieCamera")
                            case .pdf:
                                image = UIImage(named: "pdf")
                            }
                            images.append(image)
                            imagesData.append(data)
                        } else {
                            imagesData.append(nil)
                            images.append(nil)
                        }
                    }
                    
                    self.images = images.compactMap { $0 }
                    self.imagesData = imagesData.compactMap { $0 }
                    if images.count > 0 {
                        showingUploadButton = true
                    }
                }
                .padding([.leading, .trailing], 20)
            }
            .navigationTitle("Upload Photo")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isUploadButtonDisabled = true
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            settingsService.setUploadFileType(uploadFileType: .images)
                        } label: {
                            Label(UploadFileType.images.rawValue, systemImage: settingsService.uploadFileType == .images ? "checkmark.circle" : "circle")
                        }
                        Button {
                            settingsService.setUploadFileType(uploadFileType: .videos)
                        } label: {
                            Label(UploadFileType.videos.rawValue, systemImage: settingsService.uploadFileType == .videos ? "checkmark.circle" : "circle")
                        }
//                        Button {
//                            settingsService.setUploadFileType(uploadFileType: .pdf)
//                        } label: {
//                            Label(UploadFileType.pdf.rawValue, systemImage: settingsService.uploadFileType == .pdf ? "checkmark.circle" : "circle")
//                        }
                        Button {
                            
                        } label: {
                            Text("Cancel")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Upload File", isPresented: $showingUploadError) {
                Button("Ok", role: .cancel) {  }
            } message: {
                Text(fileUploadFailedMessage)
            }
            .alert("File Uploaded", isPresented: $showingSuccess) {
                Button("Ok", role: .cancel) {  }
            } message: {
                Text("Succeeded")
            }
            .alert("Image can not be uploaded", isPresented: $showingCanNotDownloadImage ) {
                Button("Ok", role: .cancel) {  }
            } message: {
                Text("Error with image, please select another one.")
            }
            .alert("Please select a folder", isPresented: $showingUploadFolderMissing) {
                Button("Ok", role: .cancel) {  }
            } message: {
                Text("You need to select a folder to upload the photo too. If no folders are present, please create one on the Photos tab.")
            }
            .fullScreenCover(isPresented: $showingAddToFoldersSheet, onDismiss: uploadPhotos) {
                SelectFolderToUpload(selectedFolder: $selectedFolder)
            }
        }
    }
    
    func uploadPhotos() {
        uploadPhotoCount = 1
        uploadPhotoOriginalCount = imagesData.count
        if selectedFolder.isEmpty == false {
            if selectedFolder == "" {
                showingUploadFolderMissing = true
                return
            }
            isButtonDisabled = true
            Task {
                guard let user = Auth.auth().currentUser else {
                    return
                }

                do {
                    for imageData in imagesData {
                        newPhoto = PhotoInfo(userfolder: selectedFolder, userId: user.uid, uploadFileType: settingsService.uploadFileType)
                        var path = "\(user.uid)/\(newPhoto.cloudStoreId)"
                        switch settingsService.uploadFileType {
                        case .images:
                            path += ".png"
                        case .videos:
                            path += ".mp4"
                        case .pdf:
                            path += ".pdf"
                        }

                        let imageReference = Storage.storage().reference(withPath: path)
                        
                        let metaData = StorageMetadata()
                        switch settingsService.uploadFileType {
                        case .images:
                            metaData.contentType = "image/png"
                        case .videos:
                            metaData.contentType = "video/quicktime"
                        case .pdf:
                            metaData.contentType = "application/pdf"
                        }
                        _ = try await imageReference.putDataAsync(imageData, metadata: metaData) { progress in
                            if let progress {
                                self.progress = progress.fractionCompleted / 2
                            }
                        }
                        newPhoto.imageURL = try await imageReference.downloadURL()
                        switch settingsService.uploadFileType {
                        case .images:
                            let storage = Storage.storage()
                            let thumbNailPath = "\(user.uid)/thumbNails/\(newPhoto.cloudStoreId)_200x200.png"
                            for _ in 1...5 {
                                try await Task.sleep(for: .seconds(1), tolerance: .seconds(1))
                                if progress! < 1 {
                                    progress! += 0.1
                                }
                            }
                            let url = try await storage.reference().child(thumbNailPath).downloadURL()
                            newPhoto.thumbnailURL = url
                        case .videos:
                            newPhoto.thumbnailURL = firebaseService.movieCameraURL
                        case .pdf:
                            newPhoto.thumbnailURL = firebaseService.movieCameraURL
                        }

                        await firebaseService.addPhotoToAllPhotos(photo: newPhoto)
                        progress = nil
                        uploadPhotoCount += 1
                        if images.count > 0 {
                            images.removeFirst()
                        }
                    }
                    selectedPhotos = []
                    showingSuccess = true
                    isButtonDisabled = false
                    showingUploadButton = false
                    selectedFolder = ""
                    self.images = []
                    self.imagesData = []
                }
                catch {
                    debugPrint("An error ocurred while uploading: \(error.localizedDescription)")
                    progress = nil
                    selectedPhotos = []
                    isButtonDisabled = false
                    showingUploadButton = false
                    selectedFolder = ""
                    self.images = []
                    self.imagesData = []
                    fileUploadFailedMessage = "An error ocurred while uploading photo number: \(uploadPhotoCount). Could not continue uploading photos."
                    showingUploadError = true
                }
            }
        }
    }
}

