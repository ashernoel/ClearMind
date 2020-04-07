//
//  RecordingListViewController.swift
//  ClearMind
//
//  Created by Asher Noel on 4/6/20.
//  Copyright © 2020 Asher Noel. All rights reserved.
//

import UIKit
import FirebaseFirestore

class RecordingListViewController: UITableViewDataSource, RecordingListViewModel, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    private var selectedRecording: Recording?
    @IBOutlet weak var createRecordingButton: UIView!
    
    private var listener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.didChangeData = { [weak self] data in
            guard let strongSelf = self else { return }
            strongSelf.tableView.reloadData()
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 200
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.addPressed))
        createRecordingButton.addGestureRecognizer(gesture)
    }
    
    @objc func addPressed(sender: UITapGestureRecognizer){
        let controller = NewRecordingViewController.fromStoryboard()
        self.navigationController?.present(controller, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.observeQuery()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopObserving()
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! RecoringTableViewCell
        let recording = viewModel.viewData.recordings[indexPath.row]
        cell.populate(recording: recording)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.viewData.recordings.count
    }
    
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.selectedRecording = viewModel.viewData.recordings[indexPath.row]
        
        let vc = RecordingDetailViewController.fromStoryboard()
        vc.recording = selectedRecording
        vc.recordingReference = viewModel.documents[indexPath.row].reference
        
        navigationController?.pushViewController(vc, animated: true)
    }
}

class RecordingTableViewCell: UITableViewCell {
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var recordingText: UILabel!
    @IBOutlet weak var ownerText: UILabel!
    
    func populate(recording: Recording) {
        recordingText.text = recording.text
        ownerText.text = recording.text
        
        let dateFormatter = DateFormatter()
        dateFormatter.dataStyle = .none
        dateFormatter.timeStyle = .short
        
        timeLabel.text = dateFormatter.string(from: recording.time)
    }
}
