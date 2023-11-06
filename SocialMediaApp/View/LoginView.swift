//
//  LoginView.swift
//  SocialMediaApp
//
//  Created by Daniel Perez Olivares on 04-11-23.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct LoginView: View {
    @State var emailID: String = ""
    @State var password: String = ""
    @State var createAccount: Bool = false
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    //Userdefaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var storedUsername: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Sign in")
                .font(.largeTitle.bold())
                .hAlignment(.leading)
            
            Text("Welcome back,\nYoy have been missed.")
                .font(.title3)
                .hAlignment(.leading)
            
            VStack(spacing: 12) {
                TextField("Email", text: $emailID)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                    .padding(.top, 25)
                
                SecureField("Password", text: $password)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                
                Button("Reset password", action: {
                    resetPassword()
                })
                    .font(.callout)
                    .fontWeight(.medium)
                    .tint(.black)
                    .hAlignment(.trailing)
                
                Button(action: loginUser) {
                    Text("Sign in")
                        .foregroundColor(.white)
                        .hAlignment(.center)
                        .fillView(.black)
                }
                .padding(.top, 10)
                
            }
            HStack {
                Text("Don't have an account")
                    .foregroundColor(.gray)
                
                Button("Register now") {
                    createAccount.toggle()
                }
                .fontWeight(.bold)
                .foregroundColor(.black)
            }
            .font(.callout)
            .vAlignment(.bottom)
        }
        .vAlignment(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        .fullScreenCover(isPresented: $createAccount) {
            RegisterView()
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    func loginUser() {
        isLoading = true
        closeKeyboard()
        Task {
            do {
                try await Auth.auth().signIn(withEmail: emailID, password: password)
                print("User found")
                try await fetchUser()
            } catch {
                await setError(error)
            }
        }
    }
    
    func resetPassword() {
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: emailID)
            } catch {
                await setError(error)
            }
        }
    }
    
    func setError(_ error: Error) async {
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
    
    //If the user is found then fetching the users from db
    func fetchUser() async throws {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let user = try await Firestore.firestore().collection("Users").document(userID).getDocument(as: User.self)
        await MainActor.run(body: {
            userUID = userID
            storedUsername = user.username
            profileURL = user.userProfileURL
            logStatus = true
        })
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

