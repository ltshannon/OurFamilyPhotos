//
//  PublicTabCarouselView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import AVKit
import PDFKit

struct PublicTabCarouselView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var settingsService: SettingsService
    @Environment(\.dismiss) var dismiss
    var externalDataService = ExternalDataService.shared
    var publicFolder: PublicFolderInfo
    @State var photoInfos: [PhotoInfo] = []
    @State var currentPage = 0
    @State var timer = Timer.publish(every: 0, on: .main, in: .common).autoconnect()
    
    init(parameters: PublicPhotosTabCarouselParameters) {
        publicFolder = parameters.item
    }
    
    var body: some View {
        NavigationStack {
            TabView(selection: $currentPage) {
                ForEach(0..<photoInfos.count, id: \.self) { index in
                    let sampleImage = photoInfos[index]
                    VStack {
                        if (sampleImage.uploadFileType == nil || sampleImage.uploadFileType == .images), let url = sampleImage.imageURL {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image, externalDataService.updateImage(image: image) {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .shadow(radius: 10)
                                        .padding()
                                } else {
                                    ProgressView()
                                }
                            }
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
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
//            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .onReceive(timer, perform: { _ in
                currentPage = (currentPage + 1) % photoInfos.count
            })
            .onAppear {
                timer = Timer.publish(every: TimeInterval(settingsService.timerInterval.rawValue), on: .main, in: .common).autoconnect()
                Task {
                    photoInfos = await firebaseService.getPhotosForPublicFolder(name: publicFolder.name)
                }
            }
        }
    }
}
