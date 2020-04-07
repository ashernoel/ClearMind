//
//  RecordingListViewData.swift
//  ClearMind
//
//  Created by Asher Noel on 4/6/20.
//  Copyright © 2020 Asher Noel. All rights reserved.
//

import Foundation


// Create Data Model to map data from Firestore
struct Recording {
    var owner: String
    var text: String
    var time: Date
    
    var dictionary: [String: Any] {
        return [
            "owner": owner,
            "time": time,
            "text": text
        ]
    }
}

extension Recording: DocumentSerializable {
    
    init?(dictionary: [String : Any]) {
        guard let owner = dictionary["owner"] as? String,
        let time = dictionary["time"] as? Date,
        let text = dictionary["text"] as? String
            else { return nil }
        
        self.init(owner: owner, text: text, time: time)
    }
}

struct RecordingListViewData {
    var recordings: [Recording]
}


