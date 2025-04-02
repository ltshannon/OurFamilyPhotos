//
//  SettingsService.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import Foundation
import SwiftUI

enum TimerInterval: Int, CaseIterable {
    case twoSeconds = 2
    case fiveSeconds = 5
    case tenSeconds = 10
}

enum PuplicPhotoDisplay: String, CaseIterable {
    case listDisplay = "List Display"
    case automaticDisplay = "Automatic Carousel Display"
    case carouselDisplay = "Carousel Display"
    case galleryDisplay = "Gallery Display"
}

enum UploadFileType: String, Codable {
    case images = "images"
    case videos = "videos"
    case pdf = "pdf"
}

class SettingsService: ObservableObject {
    static let shared = SettingsService()
    @Published var carouseAutomaticDisplay: Bool = false
    @Published var timerInterval: TimerInterval = .fiveSeconds
    @AppStorage("puplicPhotoDisplay") var puplicPhotoDisplay: PuplicPhotoDisplay = .listDisplay
    @AppStorage("uploadFileType") var uploadFileType: UploadFileType = .images
    @AppStorage("timerInterval") var timerIntervalState: TimerInterval = .fiveSeconds
    @AppStorage("firstLaunch") var firstLaunch: Bool = true
    
    init() {
        self.carouseAutomaticDisplay = false
    }

    func setTimerInterval(timerInterval: TimerInterval) {
        timerIntervalState = timerInterval
        self.timerInterval = timerInterval
    }
    
    func setPuplicPhotoDisplay(puplicPhotoDisplay: PuplicPhotoDisplay) {
        self.puplicPhotoDisplay = puplicPhotoDisplay
    }
    
    func setUploadFileType(uploadFileType: UploadFileType) {
        self.uploadFileType = uploadFileType
    }
}
