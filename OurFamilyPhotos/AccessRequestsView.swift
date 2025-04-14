//
//  AccessRequestsView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/8/25.
//

import SwiftUI

struct AccessRequestsView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State var showingGetRejectionReponseAlert = false
    @State var showingAddNameAlert = false
    @State var showingMessageEmptyAlert = false
    @State var showingNameEmptyAlert = false
    @State var newMessage = ""
    @State var newName = ""
    @State var selectedFolderId = ""
    @State var selectedAccessRequest = AccessRequest(date: Date(), folderName: "", ownerId: "", userId: "", assignedName: "", message: "")
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(firebaseService.accessRequests, id: \.id) { item in
                    VStack(alignment: .leading) {
                        Text("Date: \(item.date, style: .date) \(item.date, style: .time)")
                        Text("Name: \(item.assignedName)")
                        Text("Folder: \(item.folderName)")
                        Text("Message: \(item.message)")
                        Text("Status: " + (item.state == .waiting ? (item.ownerId == firebaseService.userId ? "waiting for your approval" : "waiting for a response") : item.state.rawValue))
                    }
                    .swipeActions(allowsFullSwipe: false) {
                        if item.ownerId == firebaseService.userId && item.state == .waiting {
                            Button {
                                selectedAccessRequest = item
                                showingAddNameAlert = true
                            } label: {
                                Text("Accept")
                            }
                            Button(role: .destructive) {
                                selectedAccessRequest = item
                                selectedFolderId = item.id ?? ""
                                showingGetRejectionReponseAlert = true
                            } label: {
                                Text("Reject")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Public Folder Access Requests")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Add A Response", isPresented: $showingGetRejectionReponseAlert) {
            TextField("", text: $newMessage)
                .keyboardType(.default)
            Button("OK") {
                if newMessage.isEmpty == true {
                    showingMessageEmptyAlert = true
                    return
                }
                Task {
//                    await firebaseService.updateStateAccessRequest(docId: selectedFolderId, state: .denied, message: newMessage, name: myName)
                    let userInfos = firebaseService.userInfos
                    let userInfo = userInfos.filter { $0.userId ?? "" == selectedAccessRequest.userId }.first
                    if let fcm = userInfo?.fcm {
                        let myName = firebaseService.userName
                        let title = "Your request has been denied"
                        let message = "Your request for access to public folder: \(selectedAccessRequest.folderName) has been denied by \(myName).\nReason: \(newMessage)"
                        await firebaseService.callFirebaseCallableFunction(fcm: fcm, title: title, body: message, silent: false)
                        newMessage = ""
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a reason for denying access")
        }
        .alert("Add Away To Identify This Person", isPresented: $showingAddNameAlert) {
            TextField("", text: $newName)
                .keyboardType(.default)
            Button("OK") {
                if newName.isEmpty == true {
                    showingNameEmptyAlert = true
                    return
                }
                Task {
                    Task {
                        await firebaseService.updateStateAccessRequest(docId: selectedAccessRequest.id ?? "", state: .approved, message: selectedAccessRequest.message, name: newName)
                        await firebaseService.updateAccessForPublicFolder(folderName: selectedAccessRequest.folderName, userId: selectedAccessRequest.userId)
                        newName = ""
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a Response")
        }
        .alert("You didn't add a response", isPresented: $showingMessageEmptyAlert) {
            Button("Cancel", role: .cancel) {
                showingGetRejectionReponseAlert = true
            }
        }
        .alert("You didn't add away to identify this person", isPresented: $showingNameEmptyAlert) {
            Button("Cancel", role: .cancel) {
                showingAddNameAlert = true
            }
        }
    }
}

#Preview {
    AccessRequestsView()
}
