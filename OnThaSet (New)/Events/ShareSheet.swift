//
//  ShareSheet.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 1/29/26.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Helper to generate shareable content from an event
struct EventShareHelper {
    
    /// Creates a shareable message with event details
    static func createShareMessage(for event: Event) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        // Parse location
        let locationParts = event.locationName.split(separator: "|").map { String($0) }
        let venueName = locationParts.first ?? "TBA"
        let cityState = locationParts.count >= 5 ? "\(locationParts[2]), \(locationParts[3])" : ""
        
        let message = """
        🎵 CHECK OUT THIS EVENT! 🎵
        
        \(event.title.uppercased())
        
        📅 \(dateFormatter.string(from: event.date))
        📍 \(venueName)
        \(cityState.isEmpty ? "" : "   \(cityState)")
        
        \(event.details.isEmpty ? "" : "ℹ️ \(event.details)\n")
        🛣️ Find more events on "ON THA SET" app!
        
        #OnThaSet #LocalEvents #\(event.category.rawValue.replacingOccurrences(of: " ", with: ""))
        """
        
        return message
    }
    
    /// Creates shareable items including image and text
    static func createShareItems(for event: Event) -> [Any] {
        var items: [Any] = []
        
        // Add the message
        let message = createShareMessage(for: event)
        items.append(message)
        
        // Add the flyer image if available
        if let imageData = event.imageData, let image = UIImage(data: imageData) {
            items.append(image)
        }
        
        return items
    }
    
    /// Creates a shareable image with event details overlay (like a story/post)
    static func createStyledShareImage(for event: Event) -> UIImage? {
        guard let imageData = event.imageData,
              let flyerImage = UIImage(data: imageData) else {
            return nil
        }
        
        // Create a styled image with branding
        let size = CGSize(width: 1080, height: 1920) // Instagram story size
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw flyer image centered
            let imageRect = CGRect(x: 90, y: 300, width: 900, height: 900)
            flyerImage.draw(in: imageRect)
            
            // Add branding at top
            let brandingText = "ON THA SET"
            let brandingAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 60, weight: .black),
                .foregroundColor: UIColor.systemYellow
            ]
            let brandingSize = brandingText.size(withAttributes: brandingAttrs)
            let brandingRect = CGRect(
                x: (size.width - brandingSize.width) / 2,
                y: 150,
                width: brandingSize.width,
                height: brandingSize.height
            )
            brandingText.draw(in: brandingRect, withAttributes: brandingAttrs)
            
            // Add event title at bottom
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 40, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let titleText = event.title.uppercased()
            let titleSize = titleText.size(withAttributes: titleAttrs)
            let titleRect = CGRect(
                x: 90,
                y: 1300,
                width: 900,
                height: 200
            )
            titleText.draw(in: titleRect, withAttributes: titleAttrs)
            
            // Add date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let dateText = "📅 " + dateFormatter.string(from: event.date)
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 30, weight: .medium),
                .foregroundColor: UIColor.systemYellow
            ]
            dateText.draw(in: CGRect(x: 90, y: 1500, width: 900, height: 50), withAttributes: dateAttrs)
            
            // Add call to action
            let ctaText = "Download ON THA SET App"
            let ctaAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            let ctaSize = ctaText.size(withAttributes: ctaAttrs)
            let ctaRect = CGRect(
                x: (size.width - ctaSize.width) / 2,
                y: 1700,
                width: ctaSize.width,
                height: ctaSize.height
            )
            ctaText.draw(in: ctaRect, withAttributes: ctaAttrs)
        }
    }
}
