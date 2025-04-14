//
//  AccessRequests.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/8/25.
//

import SwiftUI
import FirebaseFirestore

enum AccessRequestType: String, CaseIterable, Codable {
    case waiting
    case approved
    case denied
}

struct AccessRequest: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    var date: Date
    var folderName: String
    var ownerId: String
    var userId: String
    var assignedName: String
    var message: String
    var state: AccessRequestType = .waiting
}
