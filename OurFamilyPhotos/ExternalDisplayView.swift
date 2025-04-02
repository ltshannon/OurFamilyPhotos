//
//  ExternalDisplayView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/2/25.
//

import SwiftUI

struct ExternalDisplayView: View {
    var externalDataService = ExternalDataService.shared
    @State var image: Image?
    
    var body: some View {
        VStack {
            if let image = self.image {
                image
                    .resizable()
                    .scaledToFit()
            } else {
                Text("No Image")
            }
        }
        .onReceive(externalDataService.$image, perform: { value in
            if let image = value {
                self.image = image
            }
        })

    }
}

#Preview {
    ExternalDisplayView()
}
