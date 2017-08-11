//
//  UIColor+AuraColors.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 4/14/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    // MARK: - Convenience Intializers
    
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(hexRGB:Int) {
        self.init(red:(hexRGB >> 16) & 0xff, green:(hexRGB >> 8) & 0xff, blue:hexRGB & 0xff)
    }
    
    // MARK: - Ayla primary colors
    
    class func aylaHippieGreenColor() -> UIColor {
        return UIColor(hexRGB: 0x679134)
    }

    class func aylaPearColor() -> UIColor {
        return UIColor(hexRGB: 0xd6e03d)
    }

    // MARK: - Ayla secondary colors: Greens
    
    class func aylaPineGladeColor() -> UIColor {
        return UIColor(hexRGB: 0xb4cc95)
    }

    class func aylaOliveDrabColor() -> UIColor {
        return UIColor(hexRGB: 0x6d8d24)
    }

    class func aylaCamaroneColor() -> UIColor {
        return UIColor(hexRGB: 0x006227)
    }

    class func aylaCrusoeColor() -> UIColor {
        return UIColor(hexRGB: 0x004712)
    }

    // MARK: -  Ayla secondary colors: Yellows
    
    class func aylaMustardColor() -> UIColor {
        return UIColor(hexRGB: 0xffe152)
    }

    class func aylaGoldColor() -> UIColor {
        return UIColor(hexRGB: 0xffd200)
    }

    class func aylaBuddhaGoldColor() -> UIColor {
        return UIColor(hexRGB: 0x0c2a204)
    }

    // MARK: -  Ayla secondary colors: Blues
    
    class func aylaShakespeareColor() -> UIColor {
        return UIColor(hexRGB: 0x4fb3cf)
    }

    class func aylaBahamaBlueColor() -> UIColor {
        return UIColor(hexRGB: 0x006990)
    }

    class func aylaBlueStoneColor() -> UIColor {
        return UIColor(hexRGB: 0x005568)
    }
    
    class func aylaButtonBlue() -> UIColor {
        return UIColor(hexRGB: 0x4990E2)
    }

    // MARK: - Ayla secondary colors: Oranges
    
    class func aylaMeteorColor() -> UIColor {
        return UIColor(hexRGB: 0xc37c13)
    }
    
    class func aylaFieryOrangeColor() -> UIColor {
        return UIColor(hexRGB: 0xb06010)
    }
    
    class func aylaBullShotColor() -> UIColor {
        return UIColor(hexRGB: 0x80561b)
    }

    // MARK: - Ayla secondary colors: Grays
    
    class func aylaBombayColor() -> UIColor {
        return UIColor(hexRGB: 0xb0b7bc)
    }
    
    class func aylaGrayChateauColor() -> UIColor {
        return UIColor(hexRGB: 0x95a0a9)
    }
    
    class func aylaNevadaColor() -> UIColor {
        return UIColor(hexRGB: 0x5c6f7c)
    }

    class func aylaFiordColor() -> UIColor {
        return UIColor(hexRGB: 0x425968)
    }

    // MARK: -  Ayla secondary colors: Browns
    
    class func aylaPearlBushColor() -> UIColor {
        return UIColor(hexRGB: 0xede7dd)
    }
    
    class func aylaSisalColor() -> UIColor {
        return UIColor(hexRGB: 0xd9cfc0)
    }
    
    class func aylaSorrellBrownColor() -> UIColor {
        return UIColor(hexRGB: 0xc8b18b)
    }
    
    class func aylaGurkhaColor() -> UIColor {
        return UIColor(hexRGB: 0x989482)
    }

    // MARK: -  Aura Colors
    
    class func auraBadCantaloupe() -> UIColor {
        return UIColor(red: 237, green: 231, blue: 221, alpha: 1.0)
    }

    class func auraTintColor() -> UIColor {
        return UIColor.aylaHippieGreenColor()
    }

    class func auraLeafGreenColor() -> UIColor{
        return UIColor(hue: 90/360.0,
                       saturation: 87/100.0,
                       brightness: 64/100.0,
                       alpha: 1.0)
    }
    class func auraRedColor() -> UIColor{
        return UIColor(hue: 8/360.0,
                       saturation: 85/100.0,
                       brightness: 68/100.0,
                       alpha: 1.0)
    }
    class func auraDarkLeafGreenColor() -> UIColor{
        return UIColor(hue: 50/360.0,
                       saturation: 86/100.0,
                       brightness: 14/100.0,
                       alpha: 1.0)
    }
    class func auraLightSandColor() -> UIColor{
        return UIColor(hue: 53/360.0,
                       saturation: 8/100.0,
                       brightness: 89/100.0,
                       alpha: 1.0)
    }
}
