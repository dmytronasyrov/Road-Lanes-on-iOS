//
//  ImageController.swift
//  OpenCV
//
//  Created by Dmytro Nasyrov on 5/1/17.
//  Copyright © 2017 Pharos Production Inc. All rights reserved.
//

import UIKit

public final class ImageController: UIViewController {

    // MARK: Variables
    
    lazy var trainingImg = UIImage(named: "solidWhiteCurve.jpg");
    lazy var resultImgView: UIImageView = {
        let v = UIImageView(frame: .zero)
        v.contentMode = .scaleAspectFit
        v.isOpaque = true
        v.backgroundColor = UIColor.black
        
        return v
    }()
    
    // MARK: Life
    
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    override public func loadView() {
        super.loadView()
        
        view.addSubview(resultImgView)
    }
    
    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        resultImgView.frame = view.bounds;
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        resultImgView.image = CVWrapper.lanes(from: trainingImg);
    }
}
