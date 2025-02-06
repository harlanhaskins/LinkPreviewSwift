//
//  URLRequest+Extensions.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/6/25.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension URLRequest {
    mutating func setValueIfNotSet(_ value: String, forHTTPHeaderField field: String) {
        if self.value(forHTTPHeaderField: field) == nil {
            setValue(value, forHTTPHeaderField: field)
        }
    }
}
