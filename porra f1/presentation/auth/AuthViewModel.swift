//
//  AuthViewModel.swift
//  porra f1
//
//  Created by Alejandro Miranda on 19/3/23.
//

import SwiftUI
import FirebaseAuth

@MainActor class AuthViewModel: ObservableObject {
    @Published var appUser: AppUser?
    @Published var errorMessage: String = ""
    
    private let authService = AuthService()
    private let appUserService = AppUserService()
    
    func listenToAuthState() {
        Auth.auth().addStateDidChangeListener { _, authUser in
            guard authUser != nil else {
                return
            }
            
            Task {
                let (userData, error) = await self.appUserService.getUserByEmail(email: (authUser?.email ?? ""))
                if !error.isEmpty || userData == nil {
                    self.authService.revokeAccess()
                    return
                }
                
                self.appUser = AppUser(email: userData!.email)
                UserDefaults.standard.set(self.appUser!.email, forKey: "userEmail")
            }
        }
    }
    
    func signUp(emailAddress: String, password: String) async {
        let (authUser, error) = await authService.signUpWithEmailAndPassowrd(emailAddress: emailAddress, password: password)
        guard error == ""  else {
            print("There was an error: \(error)")
            self.errorMessage = error
            return
        }
        
        guard authUser != nil else {
            print("User with email \(emailAddress) not found ")
            self.errorMessage = "user-not-found"
            return
        }
        
        let (appUser, createUserError) = await self.appUserService.createNewUser(email: emailAddress)
        guard createUserError == ""  else {
            print("There was an error: \(createUserError)")
            self.errorMessage = createUserError
            return
        }
        
        self.appUser = appUser
        UserDefaults.standard.set(self.appUser!.email, forKey: "userEmail")
    }
    
    func signIn(email: String, password: String) async {
        let (authUser, error) = await authService.signInWithEmailAndPassowrd(emailAddress: email, password: password)
        guard error == ""  else {
            print("There was an error: \(error)")
            self.errorMessage = error
            return
        }
        
        guard authUser != nil else {
            print("User with email \(email) not found ")
            self.errorMessage = "user-not-found"
            return
        }
        
        let (appUser, errorMessage) = await self.appUserService.getUserByEmail(email: email)
        guard errorMessage == ""  else {
            print("There was an error: \(error)")
            self.errorMessage = error
            return
        }
        
        guard appUser != nil else {
            print("User with email \(email) not found ")
            self.errorMessage = "user-not-found"
            return
        }
        
        self.appUser = appUser
        UserDefaults.standard.set(self.appUser!.email, forKey: "userEmail")
    }

}
