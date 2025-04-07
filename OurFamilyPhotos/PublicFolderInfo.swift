//
//  PublicFolderInfo.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct PublicFolderInfo: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    var name: String = ""
    var count: Int?
    var ownerId: String
    var userAccessIds: [String]?
}
