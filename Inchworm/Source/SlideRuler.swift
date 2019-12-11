//
//  SlideRuler.swift
//  Inchworm
//
//  Created by Echo on 10/16/19.
//  Copyright © 2019 Echo. All rights reserved.
//

import UIKit

protocol SlideRulerDelegate {
    func didGetOffsetRatio(from slideRuler: SlideRuler, offsetRatio: CGFloat)
}

public class SlideRuler: UIView {
    let pointer = CALayer()
    let centralDot = CAShapeLayer()
    let slider = UIScrollView()
    
    public static var sliderOffsetRatio: CGFloat = 0.5
    public static var scaleBarNumber = 41
    public static var majorScaleBarNumber = 5
    public static var scaleWidth: CGFloat = 1
    public static var pointerWidth: CGFloat = 1
    public static var dotWidth: CGFloat = 6
    public static var autoSnapToCenter = false
    
    let scaleBarLayer: CAReplicatorLayer = {
        var r = CAReplicatorLayer()
        r.instanceCount = scaleBarNumber
        return r
    } ()
    
    let majorScaleBarLayer: CAReplicatorLayer = {
        var r = CAReplicatorLayer()
        r.instanceCount = majorScaleBarNumber
        return r
    } ()
    
    var delegate: SlideRulerDelegate?
    var reset = false
    var offsetValue: CGFloat = 0
    
    override public var bounds: CGRect {
        didSet {
            setUIFrames()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        setupSlider()
        makeRuler()
        makeCentralDot()
        makePointer()
        
        setUIFrames()
    }
    
    @objc func setSliderDelegate() {
        slider.delegate = self
    }
    
    public func setUIFrames() {
        slider.frame = bounds

        offsetValue = SlideRuler.sliderOffsetRatio * slider.frame.width
        slider.delegate = nil
        slider.contentSize = CGSize(width: frame.width * 2, height: frame.height)
        slider.contentOffset = CGPoint(x: offsetValue, y: 0)
        
        perform(#selector(setSliderDelegate), with: nil, afterDelay: 0.1)
        // slider.delegate = self

        pointer.frame = CGRect(x: (frame.width / 2 - SlideRuler.pointerWidth / 2), y: bounds.origin.y, width: SlideRuler.pointerWidth, height: frame.height)
        
        centralDot.frame = CGRect(x: frame.width - SlideRuler.dotWidth / 2, y: frame.height * 0.2, width: SlideRuler.dotWidth, height: SlideRuler.dotWidth)
        centralDot.path = UIBezierPath(ovalIn: centralDot.bounds).cgPath
        
        scaleBarLayer.frame = CGRect(x: frame.width / 2, y: 0.6 * frame.height, width: frame.width, height: 0.4 * frame.height)
        scaleBarLayer.instanceTransform = CATransform3DMakeTranslation((frame.width - SlideRuler.scaleWidth) / CGFloat((SlideRuler.scaleBarNumber - 1)) , 0, 0)

        scaleBarLayer.sublayers?.forEach {
            $0.frame = CGRect(x: 0, y: 0, width: 1, height: scaleBarLayer.frame.height)
        }
        
        majorScaleBarLayer.frame = scaleBarLayer.frame
        majorScaleBarLayer.instanceTransform = CATransform3DMakeTranslation((frame.width - SlideRuler.scaleWidth) / CGFloat((SlideRuler.majorScaleBarNumber - 1)) , 0, 0)
        
        majorScaleBarLayer.sublayers?.forEach {
            $0.frame = CGRect(x: 0, y: 0, width: 1, height: majorScaleBarLayer.frame.height)
        }
    }
    
    private func setupSlider() {
        addSubview(slider)
        
        slider.showsHorizontalScrollIndicator = false
        slider.showsVerticalScrollIndicator = false
        slider.delegate = self
    }
    
    private func makePointer() {
        pointer.backgroundColor = UIColor.white.cgColor
        layer.addSublayer(pointer)
    }
    
    private func makeCentralDot() {
        centralDot.fillColor = UIColor.white.cgColor
        slider.layer.addSublayer(centralDot)
    }
    
    private func makeRuler() {
        scaleBarLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let scaleBar = makeBarScaleMark(byColor: UIColor.gray.cgColor)
        scaleBarLayer.addSublayer(scaleBar)
        
        slider.layer.addSublayer(scaleBarLayer)
        
        majorScaleBarLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let majorScaleBar = makeBarScaleMark(byColor: UIColor.white.cgColor)
        majorScaleBarLayer.addSublayer(majorScaleBar)
        
        slider.layer.addSublayer(majorScaleBarLayer)
    }
    
    private func makeBarScaleMark(byColor color: CGColor) -> CALayer {
        let bar = CALayer()
        bar.backgroundColor = color
        
        return bar
    }
    
    func handleTempReset() {
        let offset = CGPoint(x: offsetValue, y: 0)
        slider.delegate = nil
        slider.setContentOffset(offset, animated: false)
        slider.delegate = self
        
        centralDot.isHidden = true
        let color = UIColor.gray.cgColor
        scaleBarLayer.sublayers?.forEach { $0.backgroundColor = color}
        majorScaleBarLayer.sublayers?.forEach { $0.backgroundColor = color}
    }
    
    func handleRemoveTempResetWith(progress: Float) {
        centralDot.fillColor = UIColor.white.cgColor
        
        scaleBarLayer.sublayers?.forEach { $0.backgroundColor = UIColor.gray.cgColor}
        majorScaleBarLayer.sublayers?.forEach { $0.backgroundColor = UIColor.white.cgColor}

        
        slider.delegate = nil
        let offsetX = CGFloat(progress) * offsetValue + offsetValue
        let offset = CGPoint(x: offsetX, y: 0)
        slider.setContentOffset(offset, animated: false)
        slider.delegate = self
        
        checkCentralDotHiddenStatus()
    }
    
    func checkCentralDotHiddenStatus() {
        centralDot.isHidden = (slider.contentOffset.x == frame.width / 2)
    }
}

extension SlideRuler: UIScrollViewDelegate {
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        checkCentralDotHiddenStatus()
        if SlideRuler.autoSnapToCenter {
            let offset = CGPoint(x: frame.width / 2, y: 0)
            scrollView.setContentOffset(offset, animated: false)
        }
    }
    
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if SlideRuler.autoSnapToCenter {
            let offset = CGPoint(x: frame.width / 2, y: 0)
            scrollView.setContentOffset(offset, animated: false)
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        centralDot.isHidden = false
        
        let speed = scrollView.panGestureRecognizer.velocity(in: scrollView.superview)
        
        let limit = frame.width / CGFloat((SlideRuler.scaleBarNumber - 1) * 2)
        if abs(slider.contentOffset.x - frame.width / 2) < limit && abs(speed.x) < 10.0 {
            if !reset {
                reset = true
                let offset = CGPoint(x: frame.width / 2, y: 0)
                scrollView.setContentOffset(offset, animated: false)
            }
        } else {
            reset = false
        }
        
        var offsetRatio = (slider.contentOffset.x - offsetValue) / offsetValue
        
        if offsetRatio > 1 { offsetRatio = 1.0 }
        if offsetRatio < -1 { offsetRatio = -1.0 }
        
        delegate?.didGetOffsetRatio(from: self, offsetRatio: offsetRatio)
        
        if scrollView.frame.width > 0 {
            SlideRuler.sliderOffsetRatio = scrollView.contentOffset.x / scrollView.frame.width
        }
    }
}
