import UIKit

enum ImageEncoder {
    static func dataURL(from image: UIImage, maxDimension: CGFloat = 1024, quality: CGFloat = 0.7) -> String? {
        let scaled = resize(image, maxDimension: maxDimension)
        guard let data = scaled.jpegData(compressionQuality: quality) else {
            return nil
        }
        return "data:image/jpeg;base64," + data.base64EncodedString()
    }

    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension else {
            return image
        }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

extension String {
    func decodedImage() -> UIImage? {
        guard let commaIndex = firstIndex(of: ",") else {
            return nil
        }
        let base64 = String(self[index(after: commaIndex)...])
        guard let data = Data(base64Encoded: base64) else {
            return nil
        }
        return UIImage(data: data)
    }
}
