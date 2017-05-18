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
    
    private lazy var resultImgView: UIImageView = {
        let v = UIImageView(frame: .zero)
        v.contentMode = .scaleAspectFit
        v.isOpaque = true
        v.backgroundColor = UIColor.black
        v.isExclusiveTouch = true
        v.isMultipleTouchEnabled = false
        v.isUserInteractionEnabled = true
        
        return v
    }()
    private lazy var trainingSet = [
        //"IMG_6868.jpg",
        "solidWhiteRight.jpg",
        "solidYellowCurve.jpg",
        "solidYellowCurve2.jpg",
        "solidYellowLeft.jpg",
        "whiteCarLaneSwitch.jpg",
        "solidWhiteCurve.jpg"
    ]
    private var imageIdx = 0
    
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
        
        loadImage()
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        loadImage()
    }
    
    // MARK: Private
    
    private func loadImage() {
        let file = trainingSet[imageIdx]
        print("Lading: \(file)")
        let image = UIImage(named: file)
        resultImgView.image = CVWrapper.lanes(from: image)
        
        imageIdx = imageIdx.advanced(by: 1)
        guard imageIdx >= trainingSet.count else { return }
        imageIdx = 0
    }
}
