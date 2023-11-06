//
//  ContentView.swift
//  SocialMediaApp
//
//  Created by Daniel Perez Olivares on 04-11-23.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("log_status") var logStatus: Bool = false
    var body: some View {
        if logStatus {
            //Main view
            Text("cake")
        } else {
            LoginView()
        }
       
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
