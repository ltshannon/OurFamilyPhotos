//
//  ExternalDataService.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/2/25.
//

import SwiftUI

class ExternalDataService: ObservableObject {
    static let shared = ExternalDataService()
    @Published var image: Image?
    
    func updateImage(image: Image) -> Bool {
        self.image = image
        return true
    }
    
}
