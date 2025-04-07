//
//  PublicCarouselView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import AVKit
import PDFKit

struct PublicCarouselView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    var externalDataService = ExternalDataService.shared
    var publicFolder: PublicFolderInfo
    @State var photoInfos: [PhotoInfo] = []
    @State private var scrollID: Int?
    
    init(parameters: PublicPhotosCarouselParameters) {
        publicFolder = parameters.item
    }
    
    var body: some View {
//        NavigationStack {
            VStack(alignment: .center) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(0..<photoInfos.count, id: \.self) { index in
                            let sampleImage = photoInfos[index]
                            VStack {
                                if (sampleImage.uploadFileType == nil || sampleImage.uploadFileType == .images), let url = sampleImage.imageURL {
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
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(radius: 10)
                                    .padding()
                                    
                                } else if sampleImage.uploadFileType == .videos, let url = sampleImage.imageURL  {
                                    VideoPlayer(player: AVPlayer(url: url))
                                        .scaledToFit()
                                        .cornerRadius(8.0)
                                } else if let url = sampleImage.imageURL, let pdfDoc = PDFDocument(url: url) {
                                    PDFKitView(showing: pdfDoc)
                                        .scaledToFit()
                                }
                                Text(sampleImage.description)
                                    .font(.title)
                            }
                            .containerRelativeFrame(.horizontal)
                            .scrollTransition(.animated, axis: .horizontal) { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1.0 : 0.6)
                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.6)
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $scrollID)
                .scrollTargetBehavior(.paging)
                IndicatorView(imageCount: photoInfos.count, scrollID: $scrollID)
                    .padding([.bottom], 20)
            }
            .navigationTitle("Public Folder: \(publicFolder.name)")
            .onAppear {
                Task {
                    photoInfos = await firebaseService.getPhotosForPublicFolder(name: publicFolder.name)
                }
            }
        }
//    }
}

struct IndicatorView: View {
    let imageCount: Int
    @Binding var scrollID: Int?
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(0..<imageCount, id: \.self) { indicator in
                    let index = scrollID ?? 0
                    Button {
                        withAnimation {
                            scrollID = indicator
                        }
                    } label: {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(indicator == index ? Color.white : Color(.lightGray))
                    }
                }
            }
            .padding(7)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.lightGray)).opacity(0.2))
        }
    }
}
