//
//  DetailsPhotosView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import AVKit
import PDFKit

struct DetailsPhotosView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    var externalDataService = ExternalDataService.shared
    var item: PhotoInfo
    
    init(parameters: PhotosDetailParameters) {
        item = parameters.item
    }
    
    var body: some View {
        ZStack {
            Color("Background-grey").edgesIgnoringSafeArea(.all)
            VStack {
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
                
                List {
                    Section {
                        Text(item.description)
                    } header: {
                        Text("Description")
                    }
                    Section {
                        ForEach(item.publicFolders, id: \.self) { folder in
                            Text(folder)
                        }
                    } header: {
                        Text("Public Folders")
                    }
                }
            }
            .padding([.leading, .trailing], 20)
        }
    }
}
