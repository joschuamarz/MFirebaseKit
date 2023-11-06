//
//  File.swift
//  
//
//  Created by Joschua Marz on 06.11.23.
//

import FirebaseFirestore

extension Dictionary {
    func toJsonCompatible() -> Dictionary {
        var dict = self
        dict.filter {
            $0.value is Date || $0.value is Timestamp
        }.forEach {
            if $0.value is Date {
                let date = $0.value as? Date ?? Date()
                dict[$0.key] = date.timestampString as? Value
            } else if $0.value is Timestamp {
                let date = $0.value as? Timestamp ?? Timestamp()
                dict[$0.key] = date.dateValue().timestampString as? Value
            }
        }
        return dict
    }
}

extension Date {
    var timestampString: String {
        Date.timestampFormatter.string(from: self)
    }
    
    static private var timestampFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        return dateFormatter
    }
}

extension JSONDecoder {
    static func dateSensitiveDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let date = dateFormatter
                .date(from: dateString) {
                return date
            }
    
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode date string \(dateString)"
            )
        }
        return decoder
    }
}
