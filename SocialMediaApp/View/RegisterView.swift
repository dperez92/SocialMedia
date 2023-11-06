//
//  RegisterView.swift
//  SocialMediaApp
//
//  Created by Daniel Perez Olivares on 04-11-23.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct RegisterView: View {
    @State var emailID: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var userBio: String = ""
    @State var userProfilePicData: Data?
    @Environment(\.dismiss) var dismiss
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
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
            Text("Let's register\nAccount")
                .font(.largeTitle.bold())
                .hAlignment(.leading)
            
            Text("Hello, have a wonderful journey!")
                .font(.title3)
                .hAlignment(.leading)
            
            ViewThatFits {
                ScrollView(.vertical, showsIndicators: false) {
                    helperView()
                }
                helperView()
            }
            
            HStack {
                Text("Already have an account?")
                    .foregroundColor(.gray)
                
                Button("Login now") {
                    dismiss()
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
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { newPhoto in
            if let newPhoto {
                Task {
                    do {
                        guard let imageData = try await newPhoto.loadTransferable(type: Data.self) else { return }
                        await MainActor.run(body: {
                            userProfilePicData = imageData
                        })
                    } catch {}
                }
            }
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    @ViewBuilder
    func helperView() -> some View {
        VStack(spacing: 12) {
            ZStack {
                if let userProfilePicData,
                   let image = UIImage(data: userProfilePicData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 85, height: 85)
            .clipShape(Circle())
            .contentShape(Circle())
            .padding(.top, 25)
            .onTapGesture {
                showImagePicker.toggle()
            }
            
            VStack(spacing: 12) {
                TextField("Username", text: $userName)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                
                TextField("Email", text: $emailID)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                
                SecureField("Password", text: $password)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                
                TextField("About you", text: $userBio, axis: .vertical)
                    .frame(minHeight: 100, alignment: .top)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                
                Button(action: registerUser) {
                    Text("Sign up")
                        .foregroundColor(.white)
                        .hAlignment(.center)
                        .fillView(.black)
                    
                }
                .disableWithOpacity(userName == "" || password == "" || userBio == "" || emailID == "" || userProfilePicData == nil)
                .padding(.top, 10)
            }
        }
    }
    
    func registerUser() {
        isLoading = true
        closeKeyboard()
        Task {
            do {
                //Create FB account
                try await Auth.auth().createUser(withEmail: emailID, password:  password)
                //Upload photo to the storage
                guard let userUID = Auth.auth().currentUser?.uid else { return }
                guard let imageData = userProfilePicData else { return }
                let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                let _ = try await storageRef.putDataAsync(imageData)
                //Download the url photos
                let downloadURL = try await storageRef.downloadURL()
                //Create user firebase object
                let user = User(
                    username: userName,
                    userBio: userBio,
                    userUID: userUID,
                    userEmail: emailID,
                    userProfileURL: downloadURL
                )
                //Save the user within the firebase storage
                let _ = try Firestore.firestore().collection("Users").document(userUID).setData(from:   user, completion: { error in
                    if error == nil {
                        print("Succesfully saved")
                        storedUsername = userName
                        self.userUID = userUID
                        profileURL = downloadURL
                        logStatus = true
                    }
                })
            } catch {
                //Delete account in case of faialure
                try await Auth.auth().currentUser?.delete()
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
}
