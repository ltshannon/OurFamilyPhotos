//
//  PublicGalleryView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI

struct PublicGalleryView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var publicFolder: PublicFolderInfo
    @State var photoInfos: [PhotoInfo] = []
    @State var columns = [
        GridItem(.adaptive(minimum: 80))
    ]
    
    init(parameters: PublicPhotosGalleryParameters) {
        publicFolder = parameters.item
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(photoInfos, id: \.self) { item in
                    NavigationLink {
                        let parameters = PhotosDetailParameters(item: item)
                        DetailsPhotosView(parameters: parameters)
                    } label: {
                        AsyncImage(url: item.thumbnailURL) { phase in
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
//                        .frame(height: horizontalSizeClass == .regular ? 300 : 75)
                        .cornerRadius(8.0)
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Public Folder: \(publicFolder.name)")
        .onAppear {
            columns = [GridItem(.adaptive(minimum: horizontalSizeClass == .regular ? 150 : 80))]
            Task {
                photoInfos = await firebaseService.getPhotosForPublicFolder(name: publicFolder.name)
            }
        }
    }
}
