//
//  ContentView.swift
//  actorAndCombine
//
//  Created by Kazutaka Homma on 2024-10-07.
//

import Combine
import SwiftUI

struct ContentView: View {
    let vm = ViewModel()

    var body: some View {
        VStack {
            Text("Hello, world!")
        }
        .padding()
        .onAppear(perform: {
            vm.fetch()
        })
    }
}

#Preview {
    ContentView()
}
