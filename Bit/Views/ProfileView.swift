import SwiftUI
import AuthenticationServices
import CloudKit

struct Profile: Codable {
    var name: String
    var email: String
}

struct ProfileView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var isSignedIn: Bool = false
    @State private var showAlert = false

    private let profileKey = "UserProfile"
    private let recordID = CKRecord.ID(recordName: "UserProfile")
    private let recordType = "Profile"

    var body: some View {
        VStack(spacing: 24) {
            Text("Profile")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)

            if isSignedIn {
                VStack(spacing: 16) {
                    HStack {
                        Text("Name:")
                        Spacer()
                        TextField("Your Name", text: $name)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 180)
                    }
                    HStack {
                        Text("Email:")
                        Spacer()
                        TextField("Your Email", text: $email)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 180)
                    }
                    Button("Save to Cloud") {
                        saveProfile()
                        saveProfileToCloudKit()
                        showAlert = true
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("Sync from CloudKit") {
                        loadProfileFromCloudKit()
                    }
                    .padding(.top, 4)
                    .font(.caption)
                }
                .padding()
            } else {
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let auth):
                            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                                let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                                    .compactMap { $0 }
                                    .joined(separator: " ")
                                name = fullName.isEmpty ? name : fullName
                                email = credential.email ?? email
                                isSignedIn = true
                                saveProfile()
                                saveProfileToCloudKit()
                            }
                        case .failure:
                            break
                        }
                    }
                )
                .signInWithAppleButtonStyle(.whiteOutline)
                .frame(height: 45)
                .padding(.horizontal, 40)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Profile Saved"), message: Text("Your profile info is saved to CloudKit and locally."), dismissButton: .default(Text("OK")))
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            loadProfileFromCloudKit()
            loadProfile()
        }
    }

    private func saveProfile() {
        let profile = Profile(name: name, email: email)
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }

    private func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(Profile.self, from: data) {
            name = profile.name
            email = profile.email
            isSignedIn = !(name.isEmpty && email.isEmpty)
        }
    }

    // --- CloudKit Sync ---
    private func saveProfileToCloudKit() {
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record["name"] = name as CKRecordValue
        record["email"] = email as CKRecordValue

        CKContainer.default().privateCloudDatabase.save(record) { _, error in
            if let error = error {
                print("CloudKit save error: \(error)")
            }
        }
    }

    private func loadProfileFromCloudKit() {
        CKContainer.default().privateCloudDatabase.fetch(withRecordID: recordID) { record, error in
            if let record = record {
                let cloudName = record["name"] as? String ?? ""
                let cloudEmail = record["email"] as? String ?? ""
                DispatchQueue.main.async {
                    self.name = cloudName
                    self.email = cloudEmail
                    self.isSignedIn = !(cloudName.isEmpty && cloudEmail.isEmpty)
                    self.saveProfile()
                }
            } else if let ckError = error as? CKError, ckError.code == .unknownItem {
                // No profile exists in CloudKit yet
                print("No CloudKit profile found.")
            } else if let error = error {
                print("CloudKit fetch error: \(error)")
            }
        }
    }
}
