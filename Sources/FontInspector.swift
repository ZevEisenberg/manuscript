//
//  FontInspector.swift
//  BonMot
//
//  Created by Zev Eisenberg on 11/2/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

// This is not supported by watchOS
#if os(iOS) || os(tvOS) || os(OSX)
    import Foundation
    import CoreText

#if swift(>=3.0)
    typealias FontFeatureDictionary = [String : Any]
    #else
    typealias FontFeatureDictionary = [String : AnyObject]
#endif

    public extension BONFont {

        public func has(feature theFeature: MappableFeature) -> Bool {
            let matchingFeatures = availableFeaturesDictionaries.filter { featureDict in
                guard let featureTypeIdentifier = featureDict[kCTFontFeatureTypeIdentifierKey as String] as? Int else {
                    return false
                }

                return theFeature.featureTypeIdentifiers.contains(featureTypeIdentifier)
            }

            return !matchingFeatures.isEmpty
        }

        /// Queries a font and returns its available OpenType features.
        ///
        /// - Parameter includeIDs: whether to include the integer values of the
        ///                         features' type identifiers, which are
        ///                         integers, and pretty cryptic unless you know
        ///                         what you're looking for.
        /// - Returns: A human-readable string representing the receiver's
        ///            available OpenType features.
        /// - Note: features will report whether they are "Exclusive". If a
        ///         feature is exclusive, that means that you can use only one
        ///         of its available options at a time. Otherwise, you can mix
        ///         and match any combination of its options.
        public func availableFontFeatures(includeIdentifiers includeIDs: Bool = false) -> String {
            let preamble = "Available font features of \(fontName)"
            return preamble + availableFeaturesDictionaries.map { featureDict in
                let featureName = featureDict[kCTFontFeatureTypeNameKey as String] as? String
                let exclusive = featureDict[kCTFontFeatureTypeExclusiveKey as String] as? Bool ?? false
                let selectors = featureDict[kCTFontFeatureTypeSelectorsKey as String] as? [FontFeatureDictionary] ?? []

                var resultString = ""
                resultString += "\(featureName ?? "[unknown feature]")"
                if includeIDs {
                    let featureTypeIdentifier = featureDict[kCTFontFeatureTypeIdentifierKey as String] as? Int
                    resultString += " - feature type identifier: \(featureTypeIdentifier.map(String.init(describing:)) ?? "[unknown feature identifier]")"
                }
                resultString += "\n    Exclusive: \(exclusive)"
                if !selectors.isEmpty {
                    resultString += "\n    Selectors:"
                    resultString += selectors.map { selectorDict in
                        let selectorName = selectorDict[kCTFontFeatureSelectorNameKey as String] as? String
                        let selectorIsDefault = selectorDict[kCTFontFeatureSelectorDefaultKey as String] as? Bool ?? false

                        var resultString = ""
                        resultString += "    * \(selectorName ?? "[unknown selector]")"
                        if includeIDs {
                            let selectorIdentifier = selectorDict[kCTFontFeatureSelectorIdentifierKey as String] as? Int
                            resultString += " - selector: \(selectorIdentifier.map(String.init(describing:)) ?? "[unknownSelectorIdentifier]")"
                        }
                        if selectorIsDefault {
                            resultString += " (default)"
                        }
                        return resultString
                        }.reduce("") { $0 + "\n" + $1 }
                }
                return resultString
                }.reduce("") { $0 + "\n\n" + $1 }
        }

    }

    private extension BONFont {

        var availableFeaturesDictionaries: [FontFeatureDictionary] {
            let coreTextFont = CTFontCreateWithName(
                fontName as CFString,
                pointSize,
                nil)

            guard let features = CTFontCopyFeatures(coreTextFont) else {
                return []
            }

            #if swift(>=3.0)
                let intermediateFeatures = features // so we have the same name as in Swift 2.3
            #else
                // Type gymnastics because Swift 2.3 doesn't like converting CFArray to [[String : AnyObject]] in one step
                let intermediateFeatures = features as [AnyObject]

            #endif

            guard let typedFeatures = intermediateFeatures as? [FontFeatureDictionary] else {
                fatalError("failed to convert to \([FontFeatureDictionary].self) from \(features)")
            }

            return typedFeatures

        }

    }

    /// Home-grown mapping of font features. Best documentation on the subject I could find is on [this Apple discussion thread](http://lists.apple.com/archives/coretext-dev/2011/Jan/msg00004.html).
    public enum FeatureTypeIdentifier: Int {

        case allTypographicFeatures = 0
        case ligatures = 1
        case numberSpacing = 6
        case verticalPosition = 10
        case contextualFractionalForms = 11
        case ornaments = 16
        case stylisticVariants = 18
        case numberCase = 21
        case textSpacing = 22
        case caseSensitiveLayout = 33
        case stylisticAlternates = 35
        case contextualAlternates = 36
        case lowerCase = 37
        case upperCase = 38
        case special = 128

    }

    public protocol MappableFeature {
        var featureTypeIdentifiers: [Int] { get }
    }

    extension NumberCase: MappableFeature {

        public var featureTypeIdentifiers: [Int] {
            return [FeatureTypeIdentifier.numberCase.rawValue]
        }

    }

    extension NumberSpacing: MappableFeature {

        public var featureTypeIdentifiers: [Int] {
            return [FeatureTypeIdentifier.numberSpacing.rawValue]
        }
    }

    extension VerticalPosition: MappableFeature {

        public var featureTypeIdentifiers: [Int] {
            return [FeatureTypeIdentifier.verticalPosition.rawValue]
        }

    }

    extension SmallCaps: MappableFeature {

        public var featureTypeIdentifiers: [Int] {
            switch self {
            case .disabled:
                return [
                    FeatureTypeIdentifier.upperCase.rawValue,
                    FeatureTypeIdentifier.lowerCase.rawValue,
                ]
            case .fromUppercase: return [ FeatureTypeIdentifier.upperCase.rawValue ]
            case .fromLowercase: return [ FeatureTypeIdentifier.lowerCase.rawValue ]
            }
        }

    }

    extension StylisticAlternates: MappableFeature {

        public var featureTypeIdentifiers: [Int] {
            return [ FeatureTypeIdentifier.stylisticAlternates.rawValue ]
        }

    }

    extension ContextualAlternates: MappableFeature {

        public var featureTypeIdentifiers: [Int] {
            return [ FeatureTypeIdentifier.contextualAlternates.rawValue ]
        }

    }
#endif