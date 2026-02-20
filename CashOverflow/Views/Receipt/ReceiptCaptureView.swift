import SwiftUI
import PhotosUI

struct ReceiptCaptureView: View {
    @EnvironmentObject var walletViewModel: WalletViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ReceiptScanViewModel()
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if viewModel.capturedImage == nil {
                    // Capture prompt
                    VStack(spacing: 32) {
                        Spacer()

                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 80))
                            .foregroundStyle(.blue.opacity(0.6))

                        VStack(spacing: 8) {
                            Text("Scansiona uno scontrino")
                                .font(.title2.bold())
                            Text("Scatta una foto o scegli dalla galleria.\nI dati verranno estratti automaticamente.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        VStack(spacing: 12) {
                            Button {
                                showCamera = true
                            } label: {
                                Label("Scatta foto", systemImage: "camera.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)

                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .images
                            ) {
                                Label("Scegli dalla galleria", systemImage: "photo.on.rectangle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                        .padding(.horizontal, 32)

                        Spacer()
                    }
                } else {
                    // Image preview + scanning state
                    VStack(spacing: 16) {
                        if let image = viewModel.capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 4)
                        }

                        if viewModel.isScanning {
                            VStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Analisi in corso con Gemini...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding()
                        }

                        HStack(spacing: 16) {
                            Button("Annulla") {
                                viewModel.reset()
                            }
                            .buttonStyle(.bordered)

                            if viewModel.scannedReceipt != nil {
                                Button("Conferma e salva") {
                                    showConfirmation = true
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Scansiona")
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { image in
                    viewModel.capturedImage = image
                    Task { await viewModel.scanReceipt() }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.capturedImage = image
                        await viewModel.scanReceipt()
                    }
                }
            }
            .sheet(isPresented: $showConfirmation) {
                ExpenseConfirmationView(viewModel: viewModel)
                    .environmentObject(walletViewModel)
                    .environmentObject(authViewModel)
            }
        }
    }
}
