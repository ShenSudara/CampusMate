import SwiftUI

// sign in view
struct SignInView: View {
    @EnvironmentObject private var appState: AppStateViewModel
    @EnvironmentObject private var signInViewModel: SignInViewModel
    
    @FocusState private var focusedField: Field?
    @State private var isPasswordVisible = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 28)
                
// application logo
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.bottom, 20)

// primary text
                Text("Welcome back")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color("TextPrimary"))
                    .frame(maxWidth: .infinity, alignment: .center)
                
// secondary text
                Text("Sign in to your CampusMate account")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color("TextSecondary"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 6)
                    .padding(.bottom, 24)
                
// email text field
                VStack(spacing: 12) {
                    TextField("Email", text: $signInViewModel.model.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(PrimaryTextFieldStyle())
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            signInViewModel.validateEmail()
                            focusedField = .password
                        }
                        .onChange(of: signInViewModel.model.email) { _ in
                            signInViewModel.clearErrorsAsUserTypes()
                        }

                    FieldErrorText(message: signInViewModel.emailError)
                        .padding(.bottom, 12)
                    
// password textfield
                    ZStack(alignment: .trailing) {
                        Group {
                            if isPasswordVisible {
                                TextField("Password", text: $signInViewModel.model.password)
                            } else {
                                SecureField("Password", text: $signInViewModel.model.password)
                            }
                        }
                        .textFieldStyle(PrimaryTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .password)
                        .submitLabel(.done)
                        .onSubmit {
                            attemptSignIn()
                        }

                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundStyle(Color("TextSecondary"))
                        }
                        .padding(.trailing, 12)
                    }
                    .onChange(of: signInViewModel.model.password) { _ in
                        signInViewModel.clearErrorsAsUserTypes()
                    }

                    FieldErrorText(message: signInViewModel.passwordError)
                        .padding(.bottom, 8)
                }
                
// forgot password label
                HStack{
                    Spacer()
                    Button("Forgot password?") {
                        appState.showPasswordReset()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                }
                .padding(.vertical, 14)

                Button("Sign In") {
                    attemptSignIn()
                }
                .buttonStyle(PrimaryButtonStyle())
                .opacity(signInViewModel.signInEnabled ? 1 : 0.75)

                Spacer(minLength: 20)

                HStack(spacing: 8) {
                    Text("Don't you have an account? ")
                        .foregroundStyle(.secondary)
                    Button("Sign Up") {
                        appState.showSignUp()
                    }
                    .foregroundStyle(Color.accentColor)
                }
                .font(.system(size: 14, weight: .regular))
                .padding(.top, 18)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            focusedField = .email
        }
    }

// try to signIn using given credentials by users
    private func attemptSignIn() {
        signInViewModel.validateAll()
        guard signInViewModel.isFormValid else { return }
        guard signInViewModel.trySignIn else { return}
        appState.showHome()
    }
}

#Preview {
    SignInView()
        .environmentObject(AppStateViewModel())
        .environmentObject(SignInViewModel())
}
