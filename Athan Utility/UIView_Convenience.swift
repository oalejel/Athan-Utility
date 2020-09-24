//
//  UIView_Convenience.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 9/23/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import UIKit

//size and origin getters
func width(_ v: UIView) -> CGFloat {
    return v.frame.size.width
}
func height(_ v: UIView) -> CGFloat {
    return v.frame.size.height
}
func x(_ v: UIView) -> CGFloat {
    return v.frame.origin.x
}
func y(_ v: UIView) -> CGFloat {
    return v.frame.origin.y
}
//also for CGRect
func width(_ r: CGRect) -> CGFloat {
    return r.size.width
}
func height(_ r: CGRect) -> CGFloat {
    return r.size.height
}
func x(_ r: CGRect) -> CGFloat {
    return r.origin.x
}
func y(_ r: CGRect) -> CGFloat {
    return r.origin.y
}
