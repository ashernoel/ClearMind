//
//  RecordingListViewModel.swift
//  ClearMind
//
//  Created by Asher Noel on 4/6/20.
//  Copyright © 2020 Asher Noel. All rights reserved.
//

import Foundation
import FirebaseFirestore

class RecordingListViewModel {
    var localCollection: LocalCollection<Recording>!
    var recordingsReference: DocumentReference?
    
    fileprivate var query: Query? {
        didSet {
            if let listener = listener {
                listener.remove()
                observeQuery()
            }
        }
    }
    
    private var listener: ListenerRegistration?
    var documents: [DocumentSnapshot] = []
    var didChangeData: ((RecordingListViewData) -> Void)?
    
    var viewData: RecordingListViewData {
        didSet {
            didChangeData?(viewData)
        }
    }
    
    init(viewData: RecordingListViewData) {
        self.viewData = viewData
        query = baseQuery()
    }
    
    func observeQuery() {
        guard let query = query else { return }
        stopObserving()
        
        listener = query.addSnapshotListener { [unowned self] (snapshot, error) in
            
            guard let snapshot = snapshot else {
                print("Error fetching snapshot results: \(error!)")
                return
            }
            
            let models = snapshot.documents.compactMap { (document) -> Recording? in
                if let model = Recording(dictionary: document.data()) {
                    return model
                } else {
                    print("error parsing document: \(document.data())")
                    return nil
                }
            }
            
            self.viewData.recordings = models
            self.documents = snapshot.documents
        }
    }
    
    func stopObserving() {
        listener?.remove()
    }
    
    fileprivate func baseQuery() -> Query {
        return Firestore.firestore().collection("recordings").limit(to: 50)
    }
}
