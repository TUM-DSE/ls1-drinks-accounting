//
//  BlurView.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 12.12.22.
//

import Foundation
import UIKit
import SwiftUI

struct BlurView: View {
    let style: UIBlurEffect.Style
    
    init(style: UIBlurEffect.Style = .light) {
        self.style = style
    }
    
    var body: some View {
        BlurViewRepresentable(style: style)
    }
}

struct BlurView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BlurView()
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .preferredColorScheme(.dark)
    }
}


struct BlurViewRepresentable: UIViewRepresentable {
    
    let style: UIBlurEffect.Style
    
    func makeUIView(context: UIViewRepresentableContext<BlurViewRepresentable>) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blurView, at: 0)
        NSLayoutConstraint.activate([
            blurView.heightAnchor.constraint(equalTo: view.heightAnchor),
            blurView.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        return view
    }
    
    func updateUIView(_ uiView: UIView,
                      context: UIViewRepresentableContext<BlurViewRepresentable>) {
        
    }
}
