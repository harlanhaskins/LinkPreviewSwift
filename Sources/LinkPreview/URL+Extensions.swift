//
//  URL+Extensions.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/9/25.
//
import Foundation

extension URL {
    var baseHostName: String? {
        host?.split(separator: ".").suffix(2).joined(separator: ".")
    }
}
