//
//  GetUserNameView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/10/25.
//

import SwiftUI

struct GetUserNameView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss
    @State var name: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("In order for you to use this App you need to enter a name. This name will be used to identify you in the App when you want to view other people's photos.") {
                        TextField("Name", text: $name)
                    }
                }
            }
            .navigationTitle("Get User Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await firebaseService.updateUserName(name: name)
                        }
                        dismiss()
                    } label: {
                        Text("Save")
                    }
                }
            }
        }
    }
}

#Preview {
    GetUserNameView()
}
