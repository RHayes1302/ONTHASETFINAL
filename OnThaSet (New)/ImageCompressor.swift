//
//  ImageCompressor.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 1/29/26.
//

import UIKit

struct ImageCompressor {
    /// Compresses an image to a reasonable size for storage
    /// - Parameter image: The original UIImage
    /// - Returns: Compressed image data
    static func compress(_ image: UIImage, maxSizeKB: Int = 500) -> Data? {
        // Start with reasonable quality
        var compression: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compression)
        
        let maxBytes = maxSizeKB * 1024
        
        // Reduce quality until we hit the target size
        while let data = imageData, data.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        // If still too large, resize the image
        if let data = imageData, data.count > maxBytes {
            let resizedImage = resize(image, targetSizeKB: maxSizeKB)
            imageData = resizedImage.jpegData(compressionQuality: 0.7)
        }
        
        return imageData
    }
    
    /// Resizes an image to fit within a target file size
    private static func resize(_ image: UIImage, targetSizeKB: Int) -> UIImage {
        let maxDimension: CGFloat = 1200 // Max width or height
        
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        
        // If already small enough, return original
        if ratio >= 1 { return image }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Creates a thumbnail version of an image for list views
    static func createThumbnail(_ image: UIImage, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
