//
//  DetailsPhotosView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import AVKit
import PDFKit
import FirebaseAuth

struct DetailsPhotosView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var showHierarchicalView = false
    var externalDataService = ExternalDataService.shared
    @State var item: PhotoInfo
    init(parameters: PhotosDetailParameters) {
        item = parameters.item
    }
    
    var body: some View {
        Form {
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
            if item.userId == Auth.auth().currentUser!.uid {
                Section {
                    Button {
                        showHierarchicalView = true
                    } label: {
                        HStack {
                            Text("Edit Location")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.body)
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Public Folders Access")
                }
            }
        }
        .background(Color("Background-grey").edgesIgnoringSafeArea(.all))
        .fullScreenCover(isPresented: $showHierarchicalView) {
            PublicFolderHierarchyView(item: $item)
        }
    }
    
    func getUserName(userId: String) -> String {
        if let name = firebaseService.userInfos.filter( {$0.userId == userId} ).first {
            return name.userName ?? "n/a"
        }
        return "n/a"
    }
    

}
