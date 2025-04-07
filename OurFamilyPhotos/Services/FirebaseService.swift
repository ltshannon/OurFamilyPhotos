//
//  FirebaseService.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    @Published var folderImageURL: URL?
    @Published var openFolderImageURL: URL?
    @Published var movieCameraURL: URL?
    @Published var items: [PhotoInfo] = []
    @Published var userFolderNames: [String] = []
    @Published var publicFolderInfos: [PublicFolderInfo] = []
    var photosListener: ListenerRegistration?
    var publicFoldersListener: ListenerRegistration?
    var fmc: String = ""


    let database = Firestore.firestore()
    
    @MainActor
    func listenerForUserPhotos() async {

        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var imageReference = Storage.storage().reference(withPath: "file_folder.png")
        do {
            self.folderImageURL = try await imageReference.downloadURL()
        } catch {
            fatalError("Folder image not found")
        }
        
        imageReference = Storage.storage().reference(withPath: "open_file_folder.png")
        do {
            self.openFolderImageURL = try await imageReference.downloadURL()
        } catch {
            fatalError("Folder image not found")
        }
        
        imageReference = Storage.storage().reference(withPath: "movieCamera.png")
        do {
            self.movieCameraURL = try await imageReference.downloadURL()
        } catch {
            fatalError("Folder image not found")
        }

        let listener = database.collection("allPhotos").whereField("userId", isEqualTo: user.uid).addSnapshotListener({ querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                debugPrint("🧨", "Error listenerForUserPhotos: \(error!)")
                return
            }
            var results: [PhotoInfo] = []
            var folderSet = Set<String>()
            do {
                for document in documents {
                    let data = try document.data(as: PhotoInfo.self)
                    if data.isFolder == true {
                        folderSet.insert(data.userfolder)
                    }
                    results.append(data)
                }
                self.userFolderNames = Array(folderSet).sorted()
                
                var folders: [PhotoInfo] = []
                for folderItem in folderSet {
                    let items = results.filter { $0.userfolder == folderItem && $0.isFolder == false }
                    if var realFolder = results.filter({ $0.isFolder == true && $0.userfolder == folderItem}).first {
                        realFolder.items = items
                        folders.append(realFolder)
                        folders.sort(by: { $0.userfolder < $1.userfolder })
                    }
                }

                self.items = folders
                debugPrint("count: \(results.count)")
            }
            catch {
                debugPrint("🧨", "Error reading listenerForUserPhotos: \(error.localizedDescription)")
            }

        })

        self.photosListener = listener

    }
    
    @MainActor
    func listenerForPublicFolders() async {

        let listener = database.collection("publicFolders").addSnapshotListener({ querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                debugPrint("🧨", "Error listenerForPublicPhotoInfos: \(error!)")
                return
            }
            var results: [PublicFolderInfo] = []
            do {
                for document in documents {
                    let data = try document.data(as: PublicFolderInfo.self)
                    results.append(data)
                }
                
                self.publicFolderInfos = results
            }
            catch {
                debugPrint("🧨", "Error reading listenerForPublicFolders: \(error.localizedDescription)")
            }

        })

        self.publicFoldersListener = listener
        
//        func getCount(name: String) -> Int {
//            var count: Int = 0
//            let query = database.collection("allPhotos").whereField("publicFolders", arrayContains: "Family")
//            let countQuery = query.count
//            do {
//                let snapshot = try countQuery.
//                //countQuery.getAggregation(source: .server)
//                debugPrint(snapshot.count)
//                count = Int(String("\(snapshot.count)")) ?? 0
//            } catch {
//                debugPrint(error)
//            }
//            return count
//        }

    }
    
    func getPhotosForPublicFolder(name: String) async -> [PhotoInfo] {
        
        var results: [PhotoInfo] = []
        do {
            let querySnapshot = try await database.collection("allPhotos").whereField("publicFolders", arrayContains: name).getDocuments()

            for document in querySnapshot.documents {
                let data = try document.data(as: PhotoInfo.self)
                results.append(data)
            }
            
        } catch {
            debugPrint("Error PublicFoldersDetailView:getPublicFolders: \(error)")
        }

        return results
    }
    
    func addPhotoToAllPhotos(photo: PhotoInfo) async {
        do {
            try database.collection("allPhotos").addDocument(from: photo)
        } catch let error {
            debugPrint("🧨", "Error adding photo:  \(photo.id ?? "n/a")\(error)")
        }
    }
    
    func deleteFolder(item: PublicFolderInfo) async {
        
        do {
            let query = try await database.collection("allPhotos").whereField("userId", isEqualTo: item.ownerId).whereField("publicFolders", arrayContains: item.name).getDocuments()
            for document in query.documents {
                debugPrint("\(document.documentID) => \(document.data())")
                try await database.collection("allPhotos").document(document.documentID).updateData(["publicFolders": FieldValue.arrayRemove([item.name])])
            }
            try await database.collection("publicFolders").document(item.name).delete()
        } catch {
            debugPrint(error)
        }
        
    }
    
    func deleteItem(item: PhotoInfo) async {

        if item.isFolder == true {
            if let items = item.items {
                for item in items {
                    await delete(item: item)
                }
            }
        }
        await delete(item: item)
        
    }
    
    func delete(item: PhotoInfo) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var imageReference = Storage.storage().reference(withPath: "\(user.uid)/\(item.cloudStoreId).png")
        do {
            try await imageReference.delete()
        } catch let error {
            debugPrint("🧨", "Error deleting item:  \(item.id ?? "n/a")\(error)")
        }
        imageReference = Storage.storage().reference(withPath: "\(user.uid)/thumbNails/\(item.cloudStoreId)_200x200.png")
        do {
            try await imageReference.delete()
        } catch let error {
            debugPrint("🧨", "Error deleting thumbnail item:  \(item.id ?? "n/a")\(error)")
        }
        do {
            try await database.collection("allPhotos").document(item.id ?? "n/a").delete()
        } catch {
            debugPrint("🧨", "Error deleting item: \(item.id ?? "n/a") error: \(error)")
        }
        
    }
    
    func editDescription(item: PhotoInfo, newDescription: String) async {
        if item.description != newDescription {
            guard let documentId = item.id else {
                return
            }
            let data = ["description": newDescription]
            do {
                try await database.collection("allPhotos").document(documentId).updateData(data)
                debugPrint("👌", "description updated!")
            } catch {
                debugPrint("🧨", "description update failed: \(error)")
            }
        }
    }
    
    func editFolderDescription(item: PublicFolderInfo, newName: String) async -> String? {
        guard let user = Auth.auth().currentUser else {
            return "Please log in"
        }
        if item.name != newName {
            do {
                if publicFolderInfos.filter( {$0.name == newName} ).count > 0 {
                    return "Folder name already being used"
                }
                try await database.collection("publicFolders").document(item.name).delete()
                try await database.collection("publicFolders").document(newName).setData([
                    "name": newName,
                    "ownerId": user.uid,
                ])
                let query = try await database.collection("allPhotos").whereField("userId", isEqualTo: item.ownerId).whereField("publicFolders", arrayContains: item.name).getDocuments()
                for document in query.documents {
                    debugPrint("\(document.documentID) => \(document.data())")
                    try await database.collection("allPhotos").document(document.documentID).updateData(["publicFolders": FieldValue.arrayRemove([item.name])])
                    try await database.collection("allPhotos").document(document.documentID).updateData(["publicFolders": FieldValue.arrayUnion([newName])])
                }
                debugPrint("👌", "Folder name updated!")
            } catch {
                debugPrint("🧨", "Folder name update failed: \(error)")
                return error.localizedDescription
            }
        }
        return nil
    }
    
    @MainActor
    func createFolder(name: String, folderName: String, isPublic: Bool) async -> String? {
        guard let user = Auth.auth().currentUser else {
            return "Please log in"
        }

        if isPublic == true {
            let docRef = database.collection(folderName).document(name)
            
            do {
                let document = try await docRef.getDocument()
                if document.exists {
                    return "Folder already exists"
                }
            } catch {
                debugPrint("Error getting document for folder with name: \(name) error: \(error)")
            }
            do {
                try await database.collection(folderName).document(name).setData([
                    "name": name,
                    "ownerId": user.uid,
                ])
            } catch {
                debugPrint("Error creating public folder with name: \(name) error: \(error)")
                return error.localizedDescription
            }
        } else {
            if userFolderNames.contains(folderName) {
                return "Folder already exists"
            } else {
                let folder = PhotoInfo(id: UUID().uuidString, userfolder: name, description: name, isFolder: true, thumbnailURL: self.folderImageURL, userId: user.uid, items: nil)
                items.append(folder)
                do {
                    try database.collection("allPhotos").addDocument(from: folder)
                } catch {
                    debugPrint("Error creating user folder with name: \(name) error: \(error)")
                    return error.localizedDescription
                }
            }
        }

        return nil
    }
    
    func getUserId() -> String? {
        guard let user = Auth.auth().currentUser else {
            return nil
        }
        return user.uid
    }
    
    func updateAddFCMToUser(token: String) async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        self.fmc = token
        
        let values = [
                        "fcm" : token,
                     ]
        do {
            try await database.collection("profiles").document(currentUid).updateData(values)
        } catch {
            debugPrint("🧨", "updateAddFCMToUser: \(error)")
        }
        
    }
    
}

