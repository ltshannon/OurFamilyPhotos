//
//  AppNavigationState.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import Foundation

struct PhotosDetailParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString
    var item: PhotoInfo
}

struct PhotosIsPublicParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString
    var item: PhotoInfo
}

enum PhotosNavDestination: Hashable {
    case photosDetailView(PhotosDetailParameters)
}

struct PublicPhotosCarouselParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString
    var item: PublicFolderInfo
}

struct PublicPhotosTabCarouselParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString
    var item: PublicFolderInfo
}

struct PublicPhotosListParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString
    var item: PublicFolderInfo
}

struct PublicPhotosGalleryParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString
    var item: PublicFolderInfo
}

enum PublicPhotosNavDestination: Hashable {
    case publicPhotosListView(PublicPhotosListParameters)
    case publicPhotosGalleryView(PublicPhotosGalleryParameters)
    case publicPhotosCarouselView(PublicPhotosCarouselParameters)
    case publicPhotosTabCarouselView(PublicPhotosTabCarouselParameters)
    case publicPhotosDetailView(PhotosDetailParameters)
}

class AppNavigationState: ObservableObject {
    @Published var photosNavigation: [PhotosNavDestination] = []
    @Published var photosPublicNavigation: [PublicPhotosNavDestination] = []
    
    func photosDetailView(parameters: PhotosDetailParameters) {
        photosNavigation.append(PhotosNavDestination.photosDetailView(parameters))
    }
    
    func photosPublicDetailView(parameters: PhotosDetailParameters) {
        photosPublicNavigation.append(PublicPhotosNavDestination.publicPhotosDetailView(parameters))
    }
    
    func publicPhotosCarouselView(parameters: PublicPhotosCarouselParameters) {
        photosPublicNavigation.append(PublicPhotosNavDestination.publicPhotosCarouselView(parameters))
    }
    
    func publicPhotosTabCarouselView(parameters: PublicPhotosTabCarouselParameters) {
        photosPublicNavigation.append(PublicPhotosNavDestination.publicPhotosTabCarouselView(parameters))
    }
    
    func publicPhotosListView(parameters: PublicPhotosListParameters) {
        photosPublicNavigation.append(PublicPhotosNavDestination.publicPhotosListView(parameters))
    }
    
    func publicPhotosGalleryView(parameters: PublicPhotosGalleryParameters) {
        photosPublicNavigation.append(PublicPhotosNavDestination.publicPhotosGalleryView(parameters))
    }
}
