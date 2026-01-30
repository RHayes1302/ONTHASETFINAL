//
//  EventShareView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 1/29/26.
//

import SwiftUI

struct EventShareView: View {
    @Environment(\.dismiss) private var dismiss
    
    let event: Event
    @State private var showingNativeShare = false
    @State private var showingCopiedAlert = false
    @State private var selectedShareStyle: ShareStyle = .basic
    
    enum ShareStyle {
        case basic      // Text + Image
        case story      // Styled Instagram story format
        case textOnly   // Just the text
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // HEADER
                        VStack(spacing: 10) {
                            Image(systemName: "megaphone.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.yellow)
                            
                            Text("Share This Event")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("Help spread the word and grow the community!")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                        
                        // PREVIEW
                        VStack(alignment: .leading, spacing: 15) {
                            Text("PREVIEW")
                                .font(.caption.bold())
                                .foregroundColor(.yellow)
                            
                            if selectedShareStyle == .story {
                                // Show styled share image preview
                                if let styledImage = EventShareHelper.createStyledShareImage(for: event) {
                                    Image(uiImage: styledImage)
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(15)
                                        .shadow(color: .yellow.opacity(0.3), radius: 10)
                                }
                            } else {
                                // Show basic preview
                                VStack(alignment: .leading, spacing: 10) {
                                    if selectedShareStyle != .textOnly,
                                       let imageData = event.imageData,
                                       let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 200)
                                            .cornerRadius(12)
                                    }
                                    
                                    Text(EventShareHelper.createShareMessage(for: event))
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                        
                        // SHARE STYLE SELECTOR
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SHARE STYLE")
                                .font(.caption.bold())
                                .foregroundColor(.yellow)
                            
                            HStack(spacing: 10) {
                                shareStyleButton(
                                    title: "BASIC",
                                    icon: "square.and.arrow.up",
                                    style: .basic
                                )
                                
                                shareStyleButton(
                                    title: "STORY",
                                    icon: "photo.on.rectangle",
                                    style: .story
                                )
                                
                                shareStyleButton(
                                    title: "TEXT",
                                    icon: "text.quote",
                                    style: .textOnly
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // QUICK SHARE BUTTONS
                        VStack(spacing: 12) {
                            Text("QUICK SHARE")
                                .font(.caption.bold())
                                .foregroundColor(.yellow)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Main Share Button
                            Button(action: { showingNativeShare = true }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share via...")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                            }
                            
                            // Copy Link Button
                            Button(action: copyToClipboard) {
                                HStack {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy Event Details")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.yellow)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // SOCIAL MEDIA TIPS
                        VStack(alignment: .leading, spacing: 10) {
                            Text("💡 SHARING TIPS")
                                .font(.caption.bold())
                                .foregroundColor(.yellow)
                            
                            tipRow(icon: "message.fill", text: "Text friends & family directly")
                            tipRow(icon: "photo.on.rectangle", text: "Post to Instagram/Facebook stories")
                            tipRow(icon: "ellipsis.message.fill", text: "Share in group chats")
                            tipRow(icon: "link", text: "Copy and paste everywhere!")
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.yellow)
                }
            }
            .sheet(isPresented: $showingNativeShare) {
                ShareSheet(items: getShareItems())
            }
            .alert("Copied!", isPresented: $showingCopiedAlert) {
                Button("OK") { }
            } message: {
                Text("Event details copied to clipboard")
            }
        }
    }
    
    private func shareStyleButton(title: String, icon: String, style: ShareStyle) -> some View {
        Button(action: { selectedShareStyle = style }) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption2.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selectedShareStyle == style ? Color.yellow : Color.white.opacity(0.1))
            .foregroundColor(selectedShareStyle == style ? .black : .white)
            .cornerRadius(10)
        }
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.yellow)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
        }
    }
    
    private func getShareItems() -> [Any] {
        switch selectedShareStyle {
        case .basic:
            return EventShareHelper.createShareItems(for: event)
        case .story:
            if let styledImage = EventShareHelper.createStyledShareImage(for: event) {
                return [styledImage, EventShareHelper.createShareMessage(for: event)]
            }
            return EventShareHelper.createShareItems(for: event)
        case .textOnly:
            return [EventShareHelper.createShareMessage(for: event)]
        }
    }
    
    private func copyToClipboard() {
        let message = EventShareHelper.createShareMessage(for: event)
        UIPasteboard.general.string = message
        showingCopiedAlert = true
    }
}
