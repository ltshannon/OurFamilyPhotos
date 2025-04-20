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
import FirebaseFunctions

struct UserInfo: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    var userId: String?
    var fcm: String?
    var userName: String?
}

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    @Published var folderImageURL: URL?
    @Published var openFolderImageURL: URL?
    @Published var movieCameraURL: URL?
    @Published var items: [PhotoInfo] = []
    @Published var folders: [PhotoInfo] = []
    @Published var publicFolderInfos: [PublicFolderInfo] = []
    @Published var accessRequests: [AccessRequest] = []
    @Published var userInfos: [UserInfo] = []
    @Published var userId: String = ""
    @Published var userName: String = ""
    var photosListener: ListenerRegistration?
    var publicFoldersListener: ListenerRegistration?
    var accessRequestsListener: ListenerRegistration?
    var userInfosListener: ListenerRegistration?
    var fcm: String = ""
    var foldersArray: [PhotoInfo] = []
    var userFolderNames: [String] = []
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
            self.foldersArray = []
            var parentIdSet = Set<String>()
            do {
                for document in documents {
                    let data = try document.data(as: PhotoInfo.self)
                    self.foldersArray.append(data)
                    if data.isFolder == true {
                        folderSet.insert(data.userfolder)
                        parentIdSet.insert(data.id ?? "")
                    }
                    results.append(data)
                }
                self.userFolderNames = Array(folderSet).sorted()
                
                self.foldersArray.sort { $0.parentId ?? "" < $1.parentId ?? "" }
                for item in self.foldersArray {
                    debugPrint("🥸", "id: \(item.id ?? "") parentId: \(item.parentId ?? "")")
                }

                var newArray: [PhotoInfo] = []
                for parentId in parentIdSet {
                    let items = self.foldersArray.filter { $0.parentId ?? "" == parentId }
                    var arrayIndexs: [Int] = []
                    if let parent = self.foldersArray.filter({ $0.id ?? "" == parentId }).first {
                        let items2 = results.filter { $0.userfolder == parent.userfolder && $0.isFolder == false }
                        if items2.count > 0 {
                            for item in items2 {
                                arrayIndexs.append(self.foldersArray.firstIndex(of: item) ?? 0)
                            }
                        }
                    }
                    if items.count > 0 {
                        for item in items {
                            arrayIndexs.append(self.foldersArray.firstIndex(of: item) ?? 0)
                        }
                    }
                    if let i = self.foldersArray.firstIndex(where: { $0.id == parentId }) {
                        self.foldersArray[i].childrenIndexs = arrayIndexs
                    }
                }

                for (index, _) in self.foldersArray.enumerated() {
                    self.recursiveFolder(index: index)
                }
                
                for (index, _) in self.foldersArray.enumerated() {
                    if self.foldersArray[index].parentId == nil && self.foldersArray[index].isFolder == true {
                        newArray.append(self.foldersArray[index])
                        newArray.sort { $0.description < $1.description }
                    }
                }
                
                self.items = newArray
                self.folders = newArray
                
                debugPrint("count: \(results.count)")
            }
            catch {
                debugPrint("🧨", "Error reading listenerForUserPhotos: \(error.localizedDescription)")
            }
            
        })
        
        self.photosListener = listener
        
    }
    
    func recursiveFolder(index: Int) {
        if let childrenIndexs = self.foldersArray[index].childrenIndexs {
            for childrenIndex in childrenIndexs {
                recursiveFolder(index: childrenIndex)
                if self.foldersArray[index].children != nil {
                    if self.foldersArray[index].children!.contains(self.foldersArray[childrenIndex]) { continue }
                    self.foldersArray[index].children!.append(self.foldersArray[childrenIndex])
                    self.foldersArray[index].children!.sort { $0.description < $1.description }
                } else {
                    self.foldersArray[index].children = [self.foldersArray[childrenIndex]]
                    self.foldersArray[index].children!.sort { $0.description < $1.description }
                }
            }
        }
        return
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
                
                for (index, _) in results.enumerated() {
                    if let parentid = results[index].parentId {
                        if let index2 = results.firstIndex(where: { $0.name == parentid }) {
                            if results[index2].children == nil {
                                results[index2].children = []
                            }
                            results[index2].children!.append(results[index])
                        }
                    }
                }
                
                var newArray: [PublicFolderInfo] = []
                for item in results {
                    if item.parentId == nil {
                        newArray.append(item)
                    }
                }
                self.publicFolderInfos = newArray
            }
            catch {
                debugPrint("🧨", "Error reading listenerForPublicFolders: \(error.localizedDescription)")
            }
            
        })
        
        self.publicFoldersListener = listener
        
    }
    
    @MainActor
    func listenerForAccessRequests() async {
        
        let listener = database.collection("accessRequests").addSnapshotListener({ querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                debugPrint("🧨", "Error listenerForAccessRequests: \(error!)")
                return
            }
            var results: [AccessRequest] = []
            do {
                for document in documents {
                    let data = try document.data(as: AccessRequest.self)
                    results.append(data)
                }
                results.sort { $0.date > $1.date }
                self.accessRequests = results
            }
            catch {
                debugPrint("🧨", "Error reading listenerForAccessRequests: \(error.localizedDescription)")
            }
            
        })
        
        self.accessRequestsListener = listener
        
    }
    
    @MainActor
    func listenerForUsers() async {
        
        let listener = database.collection("profiles").addSnapshotListener({ querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                debugPrint("🧨", "Error listenerForUsers: \(error!)")
                return
            }
            var results: [UserInfo] = []
            do {
                for document in documents {
                    let data = try document.data(as: UserInfo.self)
                    results.append(data)
                }
                
                self.userInfos = results
            }
            catch {
                debugPrint("🧨", "Error reading listenerForUsers: \(error.localizedDescription)")
            }
            
        })
        
        self.userInfosListener = listener
        
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

        results.sort { $0.description < $1.description }
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
            debugPrint("🧨", "Error deleteFolder: \(error)")
        }
        
    }
    
    func deleteItem(item: PhotoInfo) async {

        if item.isFolder == true {
            if let items = item.children {
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
    func createFolder(name: String, folderName: String, isPublic: Bool, parentId: String? = nil) async -> String? {
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
            var values: [String: Any] = [
                          "name"          : name,
                          "ownerId"       : user.uid,
                          "userAccessIds" : [user.uid]
                         ]
            if let parentId = parentId {
                values["parentId"] = parentId
            }
            do {
                try await database.collection(folderName).document(name).setData(values)
            } catch {
                debugPrint("Error creating public folder with name: \(name) error: \(error)")
                return error.localizedDescription
            }
        } else {
            let folderNameExists = userFolderNames.contains(name)
            if folderNameExists == true {
                return "Folder already exists"
            } else {
                let folder = PhotoInfo(id: UUID().uuidString, userfolder: name, description: name, isFolder: true, thumbnailURL: self.folderImageURL, userId: user.uid, parentId: parentId, children: nil)
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
    
    @MainActor
    func getUserId() async {
        guard let user = Auth.auth().currentUser else {
            fatalError("No user signed in")
        }
        self.userId = user.uid
    }
    
    func updateAddFCMToUser(token: String) async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        self.fcm = token
        
        let values = [
                        "fcm" : token,
                     ]
        do {
            try await database.collection("profiles").document(currentUid).updateData(values)
        } catch {
            debugPrint("🧨", "updateAddFCMToUser: \(error)")
        }
        
    }
    
    func updateStateAccessRequest(docId: String, state: AccessRequestType, message: String, name: String) async {
        let values = [
                        "assignedName" : name,
                        "state" : state.rawValue,
                        "message" : message,
                     ]
        do {
            try await database.collection("accessRequests").document(docId).updateData(values)
        } catch {
            debugPrint("🧨", "updateStateAccessRequest: \(error)")
        }
    }
    
    func addAccessRequest(folderName: String, ownerId: String, message: String, state: AccessRequestType) async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        let values: [String: Any] = [
                        "date"       : FieldValue.serverTimestamp(),
                        "assignedName": self.userName,
                        "folderName" : folderName,
                        "ownerId"    : ownerId,
                        "userId"     : currentUid,
                        "message"    : message,
                        "state"       : state.rawValue,
                    ]
        do {
            let docRef = database.collection("accessRequests").document()
            try await docRef.setData(values)
        } catch {
            debugPrint("🧨", "addAccessRequest: \(error)")
        }
        
    }
    
    func updateAccessForPublicFolder(folderName: String, userId: String) async {
        
        do {
            try await database.collection("publicFolders").document(folderName).updateData(["userAccessIds": FieldValue.arrayUnion([userId])])
        } catch {
            debugPrint("🧨", "updateAccessForPublicFolder: \(error)")
        }
    }
    
    func updateUserName(name: String) async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        do {
            let reference = database.collection("profiles").document(currentUid)
            try await reference.updateData(["userName": name])
            await MainActor.run {
                self.userName = name
            }
        } catch {
            debugPrint("🧨", "updateUserName: \(error)")
        }
    }
    
    @MainActor
    func getUserName() async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        do {
            let query = try await database.collection("profiles").whereField("userId", isEqualTo: currentUid).getDocuments()
            guard query.documents.count == 1 else {
                return
            }
            for document in query.documents {
                let data = try document.data(as: UserInfo.self)
                if let userName = data.userName {
                    self.userName = userName
                }
            }

        } catch {
            debugPrint("🧨", "Error getUserName: \(error)")
        }
        return
    }
    
    func callFirebaseCallableFunction(fcm: String, title: String, body: String, silent: Bool) async {
        lazy var functions = Functions.functions()
        
        let payload: [String : Any] = [
                        "silent": silent,
                        "fcm": fcm,
                        "title": title,
                        "body": body
                      ]
        functions.httpsCallable("sendNotification").call(payload) { result, error in
            if let error = error as NSError? {
                debugPrint(String.boom, error.localizedDescription)
            }
            if let data = result?.data {
                debugPrint("result: \(data)")
            }
            
        }
    }
    
}

