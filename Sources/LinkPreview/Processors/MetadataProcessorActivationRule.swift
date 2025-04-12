//
//  MetadataProcessorActivationRule.swift
//  LinkPreview
//
//  Created by Joe Fabisevich on 4/11/25.
//

public enum MetadataProcessorActivationRule {
    case always
    case includesHostnames([String])
    case excludesHostnames([String])
}
