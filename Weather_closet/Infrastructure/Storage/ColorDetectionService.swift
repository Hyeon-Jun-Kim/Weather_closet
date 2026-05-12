import UIKit

struct ColorSuggestion {
    let name: String
    let percentage: Double
}

final class ColorDetectionService: @unchecked Sendable {
    static let shared = ColorDetectionService()
    private init() {}

    // RGB values mirror clothingColors in ClosetView.swift (멀티 제외)
    private static let palette: [(name: String, r: Float, g: Float, b: Float)] = [
        // Achromatic
        ("블랙",        0.08, 0.08, 0.08),
        ("챠콜",        0.22, 0.22, 0.22),
        ("다크 그레이",   0.35, 0.35, 0.35),
        ("그레이",       0.55, 0.55, 0.55),
        ("라이트 그레이",  0.78, 0.78, 0.78),
        ("오프화이트",    0.92, 0.92, 0.92),
        ("화이트",       0.95, 0.95, 0.95),
        // Warm Neutrals
        ("아이보리",     0.98, 0.96, 0.90),
        ("크림",        0.97, 0.93, 0.82),
        ("베이지",       0.93, 0.86, 0.73),
        ("탄",          0.82, 0.71, 0.55),
        // Browns
        ("카멜",        0.76, 0.55, 0.26),
        ("브라운",       0.45, 0.25, 0.12),
        ("초콜렛",       0.22, 0.11, 0.04),
        // Reds
        ("와인",        0.35, 0.02, 0.08),
        ("버건디",       0.50, 0.00, 0.13),
        ("레드",        0.95, 0.07, 0.07),
        ("코랄",        1.00, 0.50, 0.31),
        ("살몬",        0.98, 0.59, 0.48),
        // Pinks
        ("핑크",        1.00, 0.60, 0.75),
        ("로즈",        0.88, 0.40, 0.51),
        ("라일락",       0.83, 0.72, 0.87),
        ("라벤더",       0.71, 0.61, 0.86),
        // Purples
        ("바이올렛",     0.56, 0.00, 0.75),
        ("퍼플",        0.58, 0.10, 0.75),
        ("마젠타",       0.85, 0.00, 0.60),
        // Oranges
        ("테라코타",     0.79, 0.38, 0.28),
        ("오렌지",       1.00, 0.58, 0.00),
        // Yellows
        ("머스타드",     0.72, 0.52, 0.04),
        ("옐로우",       1.00, 0.84, 0.00),
        ("골드",        0.85, 0.65, 0.13),
        // Greens
        ("민트",        0.55, 0.88, 0.80),
        ("세이지",       0.55, 0.65, 0.51),
        ("에메랄드",     0.05, 0.60, 0.40),
        ("카키",        0.46, 0.47, 0.26),
        ("올리브",       0.40, 0.40, 0.13),
        ("그린",        0.18, 0.55, 0.25),
        ("포레스트 그린",  0.13, 0.37, 0.13),
        // Blues / Teals / Indigos
        ("틸",          0.00, 0.50, 0.50),
        ("스카이블루",    0.53, 0.81, 0.98),
        ("라이트 인디고",  0.63, 0.76, 0.88),
        ("블루",        0.00, 0.48, 1.00),
        ("코발트",       0.00, 0.28, 0.73),
        ("워시드 인디고",  0.35, 0.48, 0.67),
        ("인디고",       0.22, 0.29, 0.51),
        ("네이비",       0.05, 0.10, 0.30),
    ]

    func detectColors(from image: UIImage, maxResults: Int = 3) async -> [ColorSuggestion] {
        guard let cgImage = image.cgImage else { return [] }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let results = Self.compute(cgImage: cgImage, maxResults: maxResults)
                continuation.resume(returning: results)
            }
        }
    }

    private static func compute(cgImage: CGImage, maxResults: Int) -> [ColorSuggestion] {
        let width  = cgImage.width
        let height = cgImage.height
        let bpp    = 4
        let bpr    = width * bpp
        var pixels = [UInt8](repeating: 0, count: height * bpr)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(
                data: &pixels,
                width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: bpr,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return [] }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // 최대 ~6400 샘플 (80×80 격자)
        let step = max(1, min(width, height) / 80)
        var counts = [String: Int]()
        var total  = 0

        var y = 0
        while y < height {
            var x = 0
            while x < width {
                let i = y * bpr + x * bpp
                let a = pixels[i + 3]
                guard a > 30 else { x += step; continue }

                // premultiplied → linear
                let af = max(Float(a) / 255.0, 0.001)
                let r  = min(Float(pixels[i])     / (255.0 * af), 1.0)
                let g  = min(Float(pixels[i + 1]) / (255.0 * af), 1.0)
                let b  = min(Float(pixels[i + 2]) / (255.0 * af), 1.0)

                let name = closestName(r: r, g: g, b: b)
                counts[name, default: 0] += 1
                total += 1
                x += step
            }
            y += step
        }

        guard total > 0 else { return [] }

        return counts
            .sorted { $0.value > $1.value }
            .prefix(maxResults)
            .map { ColorSuggestion(name: $0.key, percentage: Double($0.value) / Double(total)) }
    }

    // 지각적 가중 RGB 거리 (2R + 4G + 3B)
    private static func closestName(r: Float, g: Float, b: Float) -> String {
        var best = palette[0].name
        var bestDist = Float.greatestFiniteMagnitude
        for entry in palette {
            let dr = r - entry.r
            let dg = g - entry.g
            let db = b - entry.b
            let dist = 2*dr*dr + 4*dg*dg + 3*db*db
            if dist < bestDist { bestDist = dist; best = entry.name }
        }
        return best
    }

    // 이미지의 특정 좌표(정규화 0-1)에서 RGB 추출
    static func samplePixel(image: UIImage, nx: CGFloat, ny: CGFloat) -> (r: Float, g: Float, b: Float)? {
        guard let cgImage = image.cgImage else { return nil }
        let width  = cgImage.width
        let height = cgImage.height
        let bpp    = 4
        let bpr    = width * bpp
        var pixels = [UInt8](repeating: 0, count: height * bpr)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(
                data: &pixels,
                width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: bpr,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return nil }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let x = min(Int(nx * CGFloat(width)),  width  - 1)
        let y = min(Int(ny * CGFloat(height)), height - 1)
        let i = y * bpr + x * bpp
        let a = pixels[i + 3]
        guard a > 30 else { return nil }

        let af = max(Float(a) / 255.0, 0.001)
        let r  = min(Float(pixels[i])     / (255.0 * af), 1.0)
        let g  = min(Float(pixels[i + 1]) / (255.0 * af), 1.0)
        let b  = min(Float(pixels[i + 2]) / (255.0 * af), 1.0)
        return (r, g, b)
    }

    // 팔레트에서 가장 가까운 색상명 반환 (외부 노출용)
    static func closestPaletteName(r: Float, g: Float, b: Float) -> String {
        closestName(r: r, g: g, b: b)
    }
}
