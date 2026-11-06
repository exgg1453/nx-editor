import SwiftUI
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers

struct MediaPicker: UIViewControllerRepresentable {
    let selectionLimit: Int
    let onComplete: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = selectionLimit
        configuration.filter = .any(of: [.images, .videos])
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onComplete: ([UIImage]) -> Void

        init(onComplete: @escaping ([UIImage]) -> Void) {
            self.onComplete = onComplete
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard !results.isEmpty else {
                onComplete([])
                return
            }

            let group = DispatchGroup()
            let lock = NSLock()
            var collected: [UIImage] = []

            for result in results {
                let provider = result.itemProvider
                if provider.canLoadObject(ofClass: UIImage.self) {
                    group.enter()
                    provider.loadObject(ofClass: UIImage.self) { object, _ in
                        if let image = object as? UIImage {
                            lock.lock()
                            collected.append(image)
                            lock.unlock()
                        }
                        group.leave()
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    group.enter()
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, _ in
                        if let url = url, let frame = MediaPicker.extractFrame(from: url) {
                            lock.lock()
                            collected.append(frame)
                            lock.unlock()
                        }
                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) {
                self.onComplete(collected)
            }
        }
    }

    static func extractFrame(from url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.0, preferredTimescale: 600)
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
