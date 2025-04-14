//
//  ProfileView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/10/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss
    @State var name: String = ""
    
    var body: some View {

        VStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $name)
                }
            }
        }
        .navigationTitle("User Profile")
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
        .onAppear {
            Task {
                name = firebaseService.userName
            }
        }
    }
}

#Preview {
    ProfileView()
}
