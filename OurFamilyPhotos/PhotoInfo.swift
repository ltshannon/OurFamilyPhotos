//
//  PhotoInfo.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct PhotoInfo: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    var userfolder: String
    var cloudStoreId = UUID().uuidString
    var description: String = "No description"
    var isFolder: Bool = false
    var imageURL: URL?
    var thumbnailURL: URL?
    var videoURL: URL?
    var userId: String
    var publicFolders: [String] = []
    var uploadFileType: UploadFileType? = .images
    var parentId: String?
    var childrenIndexs: [Int]?
    var children: [PhotoInfo]?
}
